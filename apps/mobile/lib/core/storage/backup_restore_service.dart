import 'dart:convert';
import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import 'local_settings_service.dart';
import 'local_database.dart';
import 'snapshot_export_service.dart';

/// P3.1 Phase 4 — Backup restore service.
///
/// Fetches a cloud backup snapshot and applies it to local storage.
/// This is a HIGH-RISK gated operation requiring pre-check and user confirmation.
///
/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §D9 + §4.4): single-source
/// SQLite. The PR-A-era LocalProgressRepository was deleted; the
/// restore path now writes each progress entity directly to its SQLite
/// table via [LocalDatabase], scoped to the current [userId].
///
/// 需求 23 Phase D PR-D-α (plan-023-D-v2 §4.1 / Review 2 P0-1):
/// constructor accepts `http.Client client`; both pre-check fetch and
/// the snapshot fetch now route through the [AuthHttpClient]
/// AuthBootstrap installed, so requests carry `Authorization:
/// Bearer <token>`. Pre-D the fetches went out as `http.get` (no
/// auth) — the server hit the permissive fallback and pulled
/// DEV_FALLBACK_USER_ID's backup regardless of who was actually
/// signed in.
///
/// IMPORTANT semantic boundaries:
/// - restore success = current device local data updated from backup
/// - restore success != sync success (not a concept)
/// - restore success != all devices consistent
/// - restore success != future auto-sync enabled
/// - has backup != restore completed
///
/// Supported schema versions:
///   p3_2_snapshot_v1 — full restore (word_records + card_states + settings)
///   p3_1_snapshot_v2 — partial restore (word_records + settings, no card_states)
///
/// Conflict policy: last-write-wins (the restored backup overwrites local data).
class BackupRestoreService {
  final String baseUrl;
  final LocalSettingsService _settings;
  final LocalDatabase _db;
  final String _userId;
  final http.Client _client;

  BackupRestoreService({
    required this.baseUrl,
    required LocalSettingsService settings,
    required LocalDatabase db,
    required String userId,
    http.Client? client,
  })  : _settings = settings,
        _db = db,
        _userId = userId,
        _client = client ?? ApiClient.defaultHttpClient ?? http.Client();

  /// Accepted schema versions for restore.
  static const _acceptedSchemas = {
    SnapshotExportService.schemaVersion,       // p3_2_snapshot_v1
    SnapshotExportService.legacySchemaVersion, // p3_1_snapshot_v2
  };

  /// Pre-check: is there a restorable backup?
  Future<RestorePreCheckResult> preCheck() async {
    try {
      // PR-D-α: route through injected client so the request is
      // authorized as the current user (not the permissive fallback).
      final response = await _client.get(
        Uri.parse('$baseUrl/me/backup/latest/snapshot'),
      );

      if (response.statusCode != 200) {
        return const RestorePreCheckResult(status: RestorePreCheckStatus.temporarilyUnavailable);
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (data['status'] == 'no_backup_found' || data['snapshot'] == null) {
        return const RestorePreCheckResult(status: RestorePreCheckStatus.noBackupFound);
      }

      final schemaVersion = data['schema_version'] as String?;
      if (!_acceptedSchemas.contains(schemaVersion)) {
        return RestorePreCheckResult(
          status: RestorePreCheckStatus.versionNotSupported,
          backupSchemaVersion: schemaVersion,
        );
      }

      // Extract device info from snapshot if present
      final snapshot = data['snapshot'] as Map<String, dynamic>?;
      final deviceId = snapshot?['device']?['device_id'] as String?;
      final deviceModel = snapshot?['device']?['device_model'] as String?;

      return RestorePreCheckResult(
        status: RestorePreCheckStatus.restorable,
        backupSchemaVersion: schemaVersion,
        uploadedAt: data['uploaded_at'] as String?,
        deviceId: deviceId,
        deviceModel: deviceModel,
      );
    } catch (e) {
      return const RestorePreCheckResult(status: RestorePreCheckStatus.temporarilyUnavailable);
    }
  }

  /// Execute restore: fetch snapshot and apply to local storage.
  /// MUST be called only after preCheck() returns restorable AND user confirms.
  Future<RestoreResult> restore() async {
    try {
      // PR-D-α: route through injected client (auth header).
      final response = await _client.get(
        Uri.parse('$baseUrl/me/backup/latest/snapshot'),
      );

      if (response.statusCode != 200) {
        return const RestoreResult(
          status: RestoreStatus.restoreFailed,
          errorCode: 'FETCH_FAILED',
        );
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final snapshot = data['snapshot'] as Map<String, dynamic>?;

      if (snapshot == null) {
        return const RestoreResult(
          status: RestoreStatus.restoreFailed,
          errorCode: 'NO_SNAPSHOT',
        );
      }

      // Validate schema
      final schemaVersion = snapshot['schema_version'] as String?;
      if (!_acceptedSchemas.contains(schemaVersion)) {
        return RestoreResult(
          status: RestoreStatus.versionNotSupported,
          errorCode: 'SCHEMA_MISMATCH',
          errorMessage:
              'Unsupported schema: $schemaVersion. '
              'Accepted: ${_acceptedSchemas.join(', ')}',
        );
      }

      // Apply: full replace strategy (no merge)
      await _applySnapshot(snapshot);

      return RestoreResult(
        status: RestoreStatus.restoreSucceeded,
        restoredAt: DateTime.now().toUtc().toIso8601String(),
        schemaVersion: schemaVersion,
      );
    } catch (e) {
      return RestoreResult(
        status: RestoreStatus.restoreFailed,
        errorCode: 'RESTORE_ERROR',
        errorMessage: e.toString(),
      );
    }
  }

  /// Apply snapshot to local storage — full replace, no merge. All
  /// writes are scoped to this user; other users' rows are untouched.
  Future<void> _applySnapshot(Map<String, dynamic> snapshot) async {
    // 1. Restore settings (these are SP, already user-scoped via
    //    [LocalSettingsService] construction).
    final settings = snapshot['settings'] as Map<String, dynamic>?;
    if (settings != null) {
      if (settings['daily_goal'] is num) {
        await _settings.setDailyGoal((settings['daily_goal'] as num).toInt());
      }
      if (settings['sound_enabled'] is bool) {
        await _settings.setSoundEnabled(settings['sound_enabled'] as bool);
      }
      if (settings['theme'] is String) {
        await _settings.setTheme(settings['theme'] as String);
      }
      if (settings['notification_time'] is String) {
        await _settings.setNotificationTime(
            settings['notification_time'] as String);
      }
    }

    // 2. Restore progress — full replace each entity FOR THIS USER ONLY.
    final progress = snapshot['progress'] as Map<String, dynamic>?;
    if (progress != null) {
      // word_records (SQLite source of truth, user-scoped replace)
      if (progress['word_records'] is List) {
        final records = (progress['word_records'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        await _db.replaceAllWordRecords(records, userId: _userId);
      }

      // card_states (FSRS scheduling — present in p3_2_snapshot_v1 only)
      if (progress['card_states'] is List) {
        final cardStateRecords = (progress['card_states'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        await _db.replaceUserRowsInTable(
          'card_states',
          cardStateRecords,
          userId: _userId,
        );
      }

      // PR-C-β D9: the four ex-SP entities are now SQLite-sourced.
      // wordbook_progress is the only one that historically held a Map
      // instead of a List; tolerate both shapes.
      final wbp = progress['wordbook_progress'];
      if (wbp is Map) {
        await _db.replaceUserRowsInTable(
          'wordbook_progress',
          [Map<String, dynamic>.from(wbp)],
          userId: _userId,
        );
      } else if (wbp is List) {
        await _db.replaceUserRowsInTable(
          'wordbook_progress',
          wbp
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          userId: _userId,
        );
      }

      if (progress['daily_checkins'] is List) {
        await _db.replaceUserRowsInTable(
          'daily_checkins',
          (progress['daily_checkins'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          userId: _userId,
        );
      }
      if (progress['custom_wordbooks'] is List) {
        await _db.replaceUserRowsInTable(
          'custom_wordbooks',
          (progress['custom_wordbooks'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          userId: _userId,
        );
      }
      if (progress['vocabulary_notebook'] is List) {
        await _db.replaceUserRowsInTable(
          'vocabulary_notebook',
          (progress['vocabulary_notebook'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          userId: _userId,
        );
      }
    }
  }
}

/// Pre-check result before restore.
class RestorePreCheckResult {
  final RestorePreCheckStatus status;
  final String? backupSchemaVersion;
  final String? uploadedAt;
  /// Device ID from the backup (last 8 chars shown in UI for identification).
  final String? deviceId;
  /// Device model from the backup (informational).
  final String? deviceModel;

  const RestorePreCheckResult({
    required this.status,
    this.backupSchemaVersion,
    this.uploadedAt,
    this.deviceId,
    this.deviceModel,
  });

  bool get isRestorable => status == RestorePreCheckStatus.restorable;
}

/// Pre-check status.
enum RestorePreCheckStatus {
  restorable,
  noBackupFound,
  versionNotSupported,
  temporarilyUnavailable,
}

/// Restore operation result.
/// restore success = current device updated. NOT sync success.
class RestoreResult {
  final RestoreStatus status;
  final String? restoredAt;
  final String? schemaVersion;
  final String? errorCode;
  final String? errorMessage;

  const RestoreResult({
    required this.status,
    this.restoredAt,
    this.schemaVersion,
    this.errorCode,
    this.errorMessage,
  });

  bool get isSuccess => status == RestoreStatus.restoreSucceeded;
}

/// Restore status. These are RESTORE states — not sync, not merge.
enum RestoreStatus {
  restoreAvailable,
  restoring,
  restoreSucceeded,
  restoreFailed,
  versionNotSupported,
  noBackupFound,
  temporarilyUnavailable,
}
