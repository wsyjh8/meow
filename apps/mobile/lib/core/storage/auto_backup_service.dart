import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'snapshot_export_service.dart';
import 'backup_upload_service.dart';
import 'local_settings_service.dart';
import 'local_database.dart';
import '../device/device_info_service.dart';

/// Auto-backup service — triggers periodic cloud backup when conditions are met.
///
/// Trigger conditions (either one):
///   1. App moves to background (AppLifecycleState.paused)
///   2. After a review session completes (post-session hook)
///
/// Both triggers require: last auto-backup was >30 minutes ago (configurable).
///
/// Fire-and-forget pattern — callers do NOT await [triggerIfNeeded].
/// Failures are logged via [debugPrint] but NEVER surfaced to the user.
/// The user can always trigger manual backup from Settings.
///
/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.3): the
/// `auto_backup_last_at_ms` SP key is now per-user
/// `u_<userId>_auto_backup_last_at_ms`. [triggerIfNeeded] takes the
/// bound userId so the lifecycle / post-session call site (typically
/// passes `AuthScope.of(context).currentUserId`) doesn't accidentally
/// reuse the previous user's last-backup timestamp.
///
/// Multi-device conflict policy: last-write-wins.
/// The most recently uploaded backup is the authoritative one for restore.
class AutoBackupService {
  static const _kLastAutoBackupAtSuffix = 'auto_backup_last_at_ms';
  static const _autoBackupIntervalMs = 30 * 60 * 1000; // 30 minutes

  /// Exported for [SpMigrator].
  static const List<String> migratableKeySuffixes = [_kLastAutoBackupAtSuffix];

  static String _k(String userId, String suffix) => 'u_${userId}_$suffix';

  // Base URL matches the rest of the app; kept as const for consistency.
  // In production this would come from config injection.
  static const String _baseUrl = 'http://10.0.2.2:3000/api/v1';

  /// Whether an auto-backup is currently in progress (guards against re-entrancy).
  static bool _isRunning = false;

  /// True if an auto-backup should run now FOR [userId].
  ///
  /// Returns true if:
  ///   - No auto-backup has ever been recorded for this user, OR
  ///   - The last auto-backup for this user was more than
  ///     [_autoBackupIntervalMs] ago.
  static bool shouldAutoBackup(SharedPreferences prefs, String userId) {
    final lastAt = prefs.getInt(_k(userId, _kLastAutoBackupAtSuffix));
    if (lastAt == null) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastAt;
    return elapsed > _autoBackupIntervalMs;
  }

  /// Fire-and-forget: trigger auto-backup for [userId] if conditions are met.
  ///
  /// Returns immediately. The actual backup runs asynchronously in background.
  /// Safe to call from lifecycle callbacks or post-session hooks.
  static void triggerIfNeeded({required String userId}) {
    if (_isRunning) return; // prevent concurrent runs
    _runAutoBackup(userId); // intentionally not awaited
  }

  static Future<void> _runAutoBackup(String userId) async {
    _isRunning = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!shouldAutoBackup(prefs, userId)) {
        debugPrint('[AutoBackup] Skipped — last backup was recent.');
        return;
      }

      debugPrint('[AutoBackup] Starting auto-backup for $userId...');

      final settings = LocalSettingsService(prefs, userId: userId);
      final deviceInfo = DeviceInfoService();

      // PR-C-β D9: SnapshotExportService is now single-source SQLite.
      // LocalProgressRepository has been deleted; the snapshot reads
      // word_records / card_states / daily_checkins / wordbook_progress
      // / custom_wordbooks / vocabulary_notebook directly from the
      // sqflite/drift file. AutoBackupService no longer needs to plumb
      // a progress repo.
      final exportService = SnapshotExportService(
        settings: settings,
        db: LocalDatabase.instance,
        deviceInfo: deviceInfo,
        prefs: prefs,
        userId: userId,
      );

      final exportResult = await exportService.export();
      if (!exportResult.isSuccess) {
        debugPrint('[AutoBackup] Export failed: ${exportResult.errorCode}');
        return;
      }

      final uploadService = BackupUploadService(
        baseUrl: _baseUrl,
        prefs: prefs,
        userId: userId,
      );

      final uploadResult = await uploadService.upload(exportResult);

      if (uploadResult.isSuccess) {
        await prefs.setInt(
          _k(userId, _kLastAutoBackupAtSuffix),
          DateTime.now().millisecondsSinceEpoch,
        );
        debugPrint('[AutoBackup] Succeeded at ${uploadResult.uploadedAt}');
      } else {
        debugPrint('[AutoBackup] Upload failed: ${uploadResult.errorCode}');
      }
    } catch (e) {
      debugPrint('[AutoBackup] Error: $e');
    } finally {
      _isRunning = false;
    }
  }
}
