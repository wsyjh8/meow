import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_settings_service.dart';
import 'local_database.dart';
import '../device/device_info_service.dart';

/// Snapshot export service — reads from SQLite + SharedPreferences.
///
/// Schema history:
///   p3_1_snapshot_v2 — word_records + settings (no card_states)
///   p3_2_snapshot_v1 — adds card_states (FSRS scheduling) + device metadata
///
/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §D9): single-source SQLite.
/// LocalProgressRepository has been deleted; every progress entity
/// (word_records / card_states / daily_checkins / wordbook_progress /
/// custom_wordbooks / vocabulary_notebook) is read directly from the
/// SQLite tables managed by drift + LocalDatabase. The snapshot is
/// also user-scoped: every read is constrained by `WHERE user_id = ?`
/// so a multi-user device exports only the bound user's rows.
///
/// Multi-device conflict policy: last-write-wins.
/// device_id + device_model are informational only.
class SnapshotExportService {
  final LocalSettingsService _settings;
  final LocalDatabase _db;
  final DeviceInfoService? _deviceInfo;
  final SharedPreferences? _prefs;
  final String _userId;

  SnapshotExportService({
    required LocalSettingsService settings,
    required LocalDatabase db,
    required String userId,
    DeviceInfoService? deviceInfo,
    SharedPreferences? prefs,
  })  : _settings = settings,
        _db = db,
        _deviceInfo = deviceInfo,
        _prefs = prefs,
        _userId = userId;

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

    // word_records from SQLite (source of truth for study data), user-scoped.
    final wordRecords = await _db.getAllWordRecords(_userId);

    // card_states from drift/SQLite DB (FSRS scheduling state), user-scoped.
    // Exported via raw table access; 'id' column excluded — DB reassigns on restore.
    // Returns [] gracefully if the table doesn't exist (pre-migration or test env).
    List<Map<String, dynamic>> cardStates;
    try {
      final rawRows = await _db.getAllFromTableForUser('card_states', _userId);
      cardStates = rawRows.map((r) {
        final m = Map<String, dynamic>.from(r);
        m.remove('id'); // auto-increment, reassigned on restore
        return m;
      }).toList();
    } catch (_) {
      cardStates = [];
    }

    // PR-C-β D9: read the four ex-SP-backed progress entities from
    // SQLite instead of LocalProgressRepository. Each is user-scoped.
    final wordbookProgress = await _readUserTable('wordbook_progress');
    final dailyCheckins = await _readUserTable('daily_checkins');
    final customWordbooks = await _readUserTable('custom_wordbooks');
    final vocabularyNotebook = await _readUserTable('vocabulary_notebook');

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
        // PR-C-β D9: these 4 are now SQLite-sourced, not SP-sourced.
        'wordbook_progress': _wordbookProgressFromRows(wordbookProgress),
        'daily_checkins': dailyCheckins,
        'custom_wordbooks': customWordbooks,
        'vocabulary_notebook': vocabularyNotebook,
      },
    };
  }

  /// Read a user-scoped progress table. Returns [] if the table doesn't
  /// exist (test envs that don't open AppDatabase will hit this).
  Future<List<Map<String, dynamic>>> _readUserTable(String table) async {
    try {
      final raw = await _db.getAllFromTableForUser(table, _userId);
      return raw.map((r) {
        final m = Map<String, dynamic>.from(r);
        // id auto-increment is reassigned on restore — strip so the
        // restored DB picks new ids without colliding.
        m.remove('id');
        return m;
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Pre-C the SP layer held a single Map for `wordbook_progress`; the
  /// SQLite table holds one row per (user, book). To preserve the
  /// snapshot shape we surface the most recent row as a Map, falling
  /// back to null when this user has none.
  Map<String, dynamic>? _wordbookProgressFromRows(
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) return null;
    // Snapshot consumers (BackupRestoreService.applySnapshot) only read
    // the Map verbatim — we pass the most-recent row, keyed by
    // `updated_at` if multiple exist.
    rows.sort((a, b) {
      final aTs = a['updated_at'] as String? ?? '';
      final bTs = b['updated_at'] as String? ?? '';
      return bTs.compareTo(aTs);
    });
    return rows.first;
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
