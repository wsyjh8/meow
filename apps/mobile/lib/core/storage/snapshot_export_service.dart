import 'dart:convert';
import 'local_settings_service.dart';
import 'local_progress_repository.dart';
import 'local_database.dart';

/// Snapshot export service — reads from SQLite + SharedPreferences.
///
/// word_records comes from SQLite (source of truth for study data).
/// Other entities still from SharedPreferences (will migrate incrementally).
class SnapshotExportService {
  final LocalSettingsService _settings;
  final LocalProgressRepository _progress;
  final LocalDatabase _db;

  SnapshotExportService({
    required LocalSettingsService settings,
    required LocalProgressRepository progress,
    required LocalDatabase db,
  })  : _settings = settings,
        _progress = progress,
        _db = db;

  static const schemaVersion = 'p3_1_snapshot_v2';
  static const exportFormat = 'full_snapshot_json';

  /// Produce a full snapshot. Now async because SQLite reads are async.
  Future<SnapshotExportResult> export() async {
    try {
      final snapshot = await _buildSnapshot();
      final jsonString = json.encode(snapshot);

      return SnapshotExportResult(
        status: ExportStatus.success,
        snapshotJson: jsonString,
        snapshotMap: snapshot,
        schemaVersion: schemaVersion,
        exportedAt: DateTime.now().toUtc().toIso8601String(),
        byteLength: utf8.encode(jsonString).length,
      );
    } catch (e) {
      return SnapshotExportResult(
        status: ExportStatus.failed,
        errorCode: 'SERIALIZATION_FAILED',
        errorMessage: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> _buildSnapshot() async {
    final now = DateTime.now().toUtc().toIso8601String();

    // word_records from SQLite (source of truth)
    final wordRecords = await _db.getAllWordRecords();

    return {
      'schema_version': schemaVersion,
      'exported_at': now,
      'export_format': exportFormat,

      'settings': {
        'daily_goal': _settings.dailyGoal,
        'sound_enabled': _settings.soundEnabled,
        'theme': _settings.theme,
        'notification_time': _settings.notificationTime,
      },

      'progress': {
        'word_records': wordRecords, // From SQLite
        'wordbook_progress': _progress.getWordbookProgress(), // Still SharedPreferences
        'daily_checkins': _progress.getDailyCheckins(),
        'custom_wordbooks': _progress.getCustomWordbooks(),
        'vocabulary_notebook': _progress.getVocabularyNotebook(),
      },
    };
  }
}

/// Result of a snapshot export operation.
class SnapshotExportResult {
  final ExportStatus status;
  final String? snapshotJson;
  final Map<String, dynamic>? snapshotMap;
  final String? schemaVersion;
  final String? exportedAt;
  final int? byteLength;
  final String? errorCode;
  final String? errorMessage;

  const SnapshotExportResult({
    required this.status,
    this.snapshotJson,
    this.snapshotMap,
    this.schemaVersion,
    this.exportedAt,
    this.byteLength,
    this.errorCode,
    this.errorMessage,
  });

  bool get isSuccess => status == ExportStatus.success;
  bool get isFailed => status == ExportStatus.failed;
}

enum ExportStatus { success, failed }
