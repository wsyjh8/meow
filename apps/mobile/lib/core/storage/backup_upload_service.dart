import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'snapshot_export_service.dart';

/// P3.1 Phase 3 — Backup upload service.
///
/// Uploads a snapshot (from Phase 2) to the cloud backup container (backend).
/// Tracks latest backup status locally.
///
/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.3): the 4 `backup_latest_*` SP
/// keys are now `u_<userId>_backup_latest_*`. Construction takes userId so
/// a switch-account doesn't leak the previous user's backup metadata.
///
/// IMPORTANT semantic boundaries:
/// - upload success = snapshot sent to cloud container successfully
/// - upload success != sync success (not a concept in P3.1)
/// - upload success != restore success (Phase 4, gated)
/// - "has cloud backup" != "current device has been restored"
class BackupUploadService {
  final String baseUrl;
  final SharedPreferences _prefs;
  final String _userId;

  BackupUploadService({
    required this.baseUrl,
    required SharedPreferences prefs,
    required String userId,
  })  : _prefs = prefs,
        _userId = userId;

  // PR-C-β: per-user SP namespace. Suffixes exported for [SpMigrator].
  static const _kLatestStatusSuffix = 'backup_latest_status';
  static const _kLatestBackupIdSuffix = 'backup_latest_id';
  static const _kLatestUploadedAtSuffix = 'backup_latest_uploaded_at';
  static const _kLatestSchemaVersionSuffix = 'backup_latest_schema_version';

  static const List<String> migratableKeySuffixes = [
    _kLatestStatusSuffix,
    _kLatestBackupIdSuffix,
    _kLatestUploadedAtSuffix,
    _kLatestSchemaVersionSuffix,
  ];

  String _k(String suffix) => 'u_${_userId}_$suffix';

  /// Upload a snapshot to the cloud backup container.
  ///
  /// Takes a [SnapshotExportResult] from Phase 2 and sends it to the backend.
  /// Returns [BackupUploadResult] with success/failure.
  Future<BackupUploadResult> upload(SnapshotExportResult exportResult) async {
    if (!exportResult.isSuccess || exportResult.snapshotMap == null) {
      return const BackupUploadResult(
        status: BackupUploadStatus.uploadFailed,
        errorCode: 'INVALID_EXPORT',
        retryable: false,
      );
    }

    // Update local status to in-progress
    await _setLocalStatus(BackupUploadStatus.uploadInProgress);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/me/backup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'snapshot': exportResult.snapshotMap,
          'schema_version': exportResult.schemaVersion,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'succeeded') {
          final result = BackupUploadResult(
            status: BackupUploadStatus.uploadSucceeded,
            backupId: data['backup_id'] as String?,
            uploadedAt: data['uploaded_at'] as String?,
            serverSchemaVersion: data['schema_version'] as String?,
          );
          await _saveLatestResult(result);
          return result;
        }
      }

      // Server returned error
      await _setLocalStatus(BackupUploadStatus.uploadFailed);
      return const BackupUploadResult(
        status: BackupUploadStatus.uploadFailed,
        errorCode: 'SERVER_ERROR',
        retryable: true,
      );
    } catch (e) {
      await _setLocalStatus(BackupUploadStatus.uploadFailed);
      return BackupUploadResult(
        status: BackupUploadStatus.uploadFailed,
        errorCode: 'NETWORK_ERROR',
        errorMessage: e.toString(),
        retryable: true,
      );
    }
  }

  /// Get the latest backup status from local storage.
  LatestBackupInfo getLatestBackupInfo() {
    final statusStr = _prefs.getString(_k(_kLatestStatusSuffix));
    final status = BackupUploadStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => BackupUploadStatus.noBackupYet,
    );
    return LatestBackupInfo(
      status: status,
      backupId: _prefs.getString(_k(_kLatestBackupIdSuffix)),
      uploadedAt: _prefs.getString(_k(_kLatestUploadedAtSuffix)),
      schemaVersion: _prefs.getString(_k(_kLatestSchemaVersionSuffix)),
    );
  }

  Future<void> _saveLatestResult(BackupUploadResult result) async {
    await _prefs.setString(_k(_kLatestStatusSuffix), result.status.name);
    if (result.backupId != null) {
      await _prefs.setString(_k(_kLatestBackupIdSuffix), result.backupId!);
    }
    if (result.uploadedAt != null) {
      await _prefs.setString(_k(_kLatestUploadedAtSuffix), result.uploadedAt!);
    }
    if (result.serverSchemaVersion != null) {
      await _prefs.setString(
          _k(_kLatestSchemaVersionSuffix), result.serverSchemaVersion!);
    }
  }

  Future<void> _setLocalStatus(BackupUploadStatus status) async {
    await _prefs.setString(_k(_kLatestStatusSuffix), status.name);
  }
}

/// Upload operation result.
/// This is UPLOAD result — NOT sync result, NOT restore result.
class BackupUploadResult {
  final BackupUploadStatus status;
  final String? backupId;
  final String? uploadedAt;
  final String? serverSchemaVersion;
  final String? errorCode;
  final String? errorMessage;
  final bool retryable;

  const BackupUploadResult({
    required this.status,
    this.backupId,
    this.uploadedAt,
    this.serverSchemaVersion,
    this.errorCode,
    this.errorMessage,
    this.retryable = false,
  });

  bool get isSuccess => status == BackupUploadStatus.uploadSucceeded;
}

/// Latest backup info (read from local storage).
class LatestBackupInfo {
  final BackupUploadStatus status;
  final String? backupId;
  final String? uploadedAt;
  final String? schemaVersion;

  const LatestBackupInfo({
    required this.status,
    this.backupId,
    this.uploadedAt,
    this.schemaVersion,
  });
}

/// Backup upload status.
/// These are UPLOAD states — not sync, not restore.
enum BackupUploadStatus {
  noBackupYet,
  uploadInProgress,
  uploadSucceeded,
  uploadFailed,
  retrying,
  temporarilyUnavailable,
}
