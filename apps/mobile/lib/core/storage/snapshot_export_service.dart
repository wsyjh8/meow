import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_settings_service.dart';
import 'local_progress_repository.dart';
import 'local_database.dart';
import '../device/device_info_service.dart';

/// Snapshot export service — reads from SQLite + SharedPreferences.
///
/// Schema history:
///   p3_1_snapshot_v2 — word_records + settings (no card_states)
///   p3_2_snapshot_v1 — adds card_states (FSRS scheduling) + device metadata
///
/// word_records and card_states come from SQLite (source of truth).
/// Other entities still from SharedPreferences (will migrate incrementally).
///
/// Multi-device conflict policy: last-write-wins.
/// device_id + device_model are informational only.
class SnapshotExportService {
  final LocalSettingsService _settings;
  final LocalProgressRepository _progress;
  final LocalDatabase _db;
  final DeviceInfoService? _deviceInfo;
  final SharedPreferences? _prefs;

  SnapshotExportService({
    required LocalSettingsService settings,
    required LocalProgressRepository progress,
    required LocalDatabase db,
    DeviceInfoService? deviceInfo,
    SharedPreferences? prefs,
  })  : _settings = settings,
        _progress = progress,
        _db = db,
        _deviceInfo = deviceInfo,
        _prefs = prefs;

  /// Current schema version — includes card_states + device metadata.
  static const schemaVersion = 'p3_2_snapshot_v1';

  /// Legacy schema version — still accepted for restore but not produced.
  static const legacySchemaVersion = 'p3_1_snapshot_v2';

  static const exportFormat = 'full_snapshot_json';

  /// Produce a full snapshot. Async because SQLite + device_info reads are async.
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

    // word_records from SQLite (source of truth for study data)
    final wordRecords = await _db.getAllWordRecords();

    // card_states from drift/SQLite DB (FSRS scheduling state).
    // Exported via raw table access; 'id' column excluded — DB reassigns on restore.
    // Returns [] gracefully if the table doesn't exist (pre-migration or test env).
    List<Map<String, dynamic>> cardStates;
    try {
      final rawRows = await _db.getAllFromTable('card_states');
      cardStates = rawRows.map((r) {
        final m = Map<String, dynamic>.from(r);
        m.remove('id'); // auto-increment, reassigned on restore
        return m;
      }).toList();
    } catch (_) {
      cardStates = [];
    }

    // Device info — optional, falls back to null if not provided
    String? deviceId;
    String? deviceModel;
    if (_deviceInfo != null && _prefs != null) {
      deviceId = await _deviceInfo!.getDeviceId(_prefs!);
      deviceModel = await _deviceInfo!.getDeviceModel();
    }

    return {
      'schema_version': schemaVersion,
      'exported_at': now,
      'export_format': exportFormat,

      // Device metadata for backup provenance
      'device': {
        'device_id': deviceId,
        'device_model': deviceModel,
      },

      'settings': {
        'daily_goal': _settings.dailyGoal,
        'sound_enabled': _settings.soundEnabled,
        'theme': _settings.theme,
        'notification_time': _settings.notificationTime,
      },

      'progress': {
        'word_records': wordRecords, // From SQLite
        'card_states': cardStates, // From drift/SQLite (FSRS state)
        'wordbook_progress': _progress.getWordbookProgress(), // SharedPreferences
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
