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
      if (schemaVersion != SnapshotExportService.schemaVersion) {
        return RestorePreCheckResult(
          status: RestorePreCheckStatus.versionNotSupported,
          backupSchemaVersion: schemaVersion,
        );
      }

      return RestorePreCheckResult(
        status: RestorePreCheckStatus.restorable,
        backupSchemaVersion: schemaVersion,
        uploadedAt: data['uploaded_at'] as String?,
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
      if (schemaVersion != SnapshotExportService.schemaVersion) {
        return RestoreResult(
          status: RestoreStatus.versionNotSupported,
          errorCode: 'SCHEMA_MISMATCH',
          errorMessage: 'Expected ${SnapshotExportService.schemaVersion}, got $schemaVersion',
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
      if (settings['daily_goal'] is num) await _settings.setDailyGoal((settings['daily_goal'] as num).toInt());
      if (settings['sound_enabled'] is bool) await _settings.setSoundEnabled(settings['sound_enabled'] as bool);
      if (settings['theme'] is String) await _settings.setTheme(settings['theme'] as String);
      if (settings['notification_time'] is String) await _settings.setNotificationTime(settings['notification_time'] as String);
    }

    // 2. Restore progress — full replace each entity
    final progress = snapshot['progress'] as Map<String, dynamic>?;
    if (progress != null) {
      if (progress['word_records'] is List) {
        final records = (progress['word_records'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        // Write to SharedPreferences (backward compat)
        await _progress.setWordRecords(records);
        // Write to SQLite (source of truth)
        await _db.replaceAllWordRecords(records);
      }
      if (progress['wordbook_progress'] is Map) {
        await _progress.setWordbookProgress(Map<String, dynamic>.from(progress['wordbook_progress'] as Map));
      }
      if (progress['daily_checkins'] is List) {
        await _progress.setDailyCheckins(
          (progress['daily_checkins'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      }
      if (progress['custom_wordbooks'] is List) {
        await _progress.setCustomWordbooks(
          (progress['custom_wordbooks'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      }
      if (progress['vocabulary_notebook'] is List) {
        await _progress.setVocabularyNotebook(
          (progress['vocabulary_notebook'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
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

  const RestorePreCheckResult({required this.status, this.backupSchemaVersion, this.uploadedAt});

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

  const RestoreResult({required this.status, this.restoredAt, this.schemaVersion, this.errorCode, this.errorMessage});

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
