import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_settings_service.dart';
import 'local_progress_repository.dart';
import 'local_database.dart';
import 'snapshot_export_service.dart';

/// P3.1 Phase 4 — Backup restore service.
///
/// Fetches a cloud backup snapshot and applies it to local storage.
/// This is a HIGH-RISK gated operation requiring pre-check and user confirmation.
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
  final LocalProgressRepository _progress;
  final LocalDatabase _db;

  BackupRestoreService({
    required this.baseUrl,
    required LocalSettingsService settings,
    required LocalProgressRepository progress,
    required LocalDatabase db,
  })  : _settings = settings,
        _progress = progress,
        _db = db;

  /// Accepted schema versions for restore.
  static const _acceptedSchemas = {
    SnapshotExportService.schemaVersion,       // p3_2_snapshot_v1
    SnapshotExportService.legacySchemaVersion, // p3_1_snapshot_v2
  };

  /// Pre-check: is there a restorable backup?
  Future<RestorePreCheckResult> preCheck() async {
    try {
      final response = await http.get(
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
      // Fetch snapshot
      final response = await http.get(
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

  /// Apply snapshot to local storage — full replace, no merge.
  Future<void> _applySnapshot(Map<String, dynamic> snapshot) async {
    // 1. Restore settings
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

    // 2. Restore progress — full replace each entity
    final progress = snapshot['progress'] as Map<String, dynamic>?;
    if (progress != null) {
      // word_records (SQLite source of truth)
      if (progress['word_records'] is List) {
        final records = (progress['word_records'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        await _progress.setWordRecords(records);
        await _db.replaceAllWordRecords(records);
      }

      // card_states (FSRS scheduling — present in p3_2_snapshot_v1 only)
      if (progress['card_states'] is List) {
        final cardStateRecords = (progress['card_states'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        await _db.replaceAllInTable('card_states', cardStateRecords);
      }

      // SharedPreferences-backed progress entities
      if (progress['wordbook_progress'] is Map) {
        await _progress.setWordbookProgress(
            Map<String, dynamic>.from(progress['wordbook_progress'] as Map));
      }
      if (progress['daily_checkins'] is List) {
        await _progress.setDailyCheckins(
          (progress['daily_checkins'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
      }
      if (progress['custom_wordbooks'] is List) {
        await _progress.setCustomWordbooks(
          (progress['custom_wordbooks'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
        );
      }
      if (progress['vocabulary_notebook'] is List) {
        await _progress.setVocabularyNotebook(
          (progress['vocabulary_notebook'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
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
