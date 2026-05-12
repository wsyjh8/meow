/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.3): SharedPreferences
/// namespace migration.
///
/// Pre-C SP layout was flat: `settings_daily_goal`, `backup_latest_id`,
/// `auto_backup_last_at_ms`, `room_canvas_layout_v1`, … all global.
/// Post-C these become per-user: `u_<userId>_settings_daily_goal`, etc.
///
/// This migrator runs once on first launch of a C-aware build and
/// rewrites any pre-C keys it finds into the current user's namespace.
/// The 5 `progress_*` keys are DELETE-only (plan D9 — the SQLite layer
/// is the truth; LocalProgressRepository is being retired).
///
/// Idempotency: the `auth_pending_sp_migration` flag (set by
/// `AuthStorage.markFreshInstallIfNeeded` in PR-C-α) is the only
/// reliable signal that migration is needed. After a successful run we
/// flip it false so subsequent launches skip the whole thing.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/auto_backup_service.dart';
import '../storage/backup_upload_service.dart';
import '../storage/local_settings_service.dart';
import 'auth_storage.dart';

class SpMigrator {
  /// 5 `progress_*` keys that get DELETED rather than namespaced.
  /// Plan §D9: the SQLite tables are the single source of truth; the
  /// SP-backed `LocalProgressRepository` was a dual-write that PR-C-β
  /// retires.
  static const List<String> _deleteOnlyKeys = <String>[
    'progress_word_records',
    'progress_wordbook_progress',
    'progress_daily_checkins',
    'progress_custom_wordbooks',
    'progress_vocabulary_notebook',
  ];

  /// All key suffixes that get renamed `flat_key` → `u_<userId>_flat_key`.
  /// Sourced from each service's [migratableKeySuffixes] list so the
  /// migration contract stays co-located with the consumer code.
  static List<String> get migratableKeySuffixes => [
        ...LocalSettingsService.migratableKeySuffixes,
        ...BackupUploadService.migratableKeySuffixes,
        ...AutoBackupService.migratableKeySuffixes,
        // RoomCanvasStorage's suffix lives in the features/ tree; we
        // hard-code it here to avoid an upward import. Keep in sync with
        // RoomCanvasStorage.migratableKeySuffixes.
        'room_canvas_layout_v1',
      ];

  final SharedPreferences _prefs;
  final AuthStorage _storage;

  SpMigrator({
    required SharedPreferences prefs,
    required AuthStorage storage,
  })  : _prefs = prefs,
        _storage = storage;

  /// Run the migration for [userId] if the pending flag is set.
  ///
  /// Returns true if migration ran, false if it was skipped (no pending
  /// flag → no pre-C data on this device, fresh install, or already
  /// migrated). Both outcomes are normal.
  Future<bool> runIfNeeded({required String userId}) async {
    if (!_storage.readPendingSpMigration()) {
      // markFreshInstallIfNeeded already classified this as a fresh
      // install (or β.5 migration completed previously). Nothing to do.
      return false;
    }

    if (userId.isEmpty) {
      debugPrint('[SpMigrator] empty userId — refusing to migrate.');
      return false;
    }

    try {
      // 1. Rename `<suffix>` → `u_<userId>_<suffix>` for each migratable
      //    SP key that still exists at the flat top-level. Skip if the
      //    target already has a value (don't overwrite per-user state
      //    that may have been written by a partial earlier run).
      for (final suffix in migratableKeySuffixes) {
        if (!_prefs.containsKey(suffix)) continue;

        final targetKey = 'u_${userId}_$suffix';
        if (!_prefs.containsKey(targetKey)) {
          await _copyKey(suffix, targetKey);
        }
        await _prefs.remove(suffix);
      }

      // 2. Drop `progress_*` keys outright (plan §D9). No new-namespace
      //    counterpart is created — the SQLite tables already carry
      //    this user's rows after PR-C-α's drift v13 backfill.
      for (final key in _deleteOnlyKeys) {
        await _prefs.remove(key);
      }

      // 3. Flip the pending flag so subsequent launches no-op.
      await _storage.writePendingSpMigration(false);
      return true;
    } catch (e, st) {
      // Leave pending=true so the next launch retries. Don't let SP
      // migration crash the app — drift v13 already gave every row a
      // user_id and downstream services have transitional fallbacks.
      debugPrint('[SpMigrator] migration failed (will retry next launch): '
          '$e\n$st');
      return false;
    }
  }

  /// Copy whatever type the value is under [from] into [to]. SP doesn't
  /// expose a generic `copy` so we probe each supported type.
  Future<void> _copyKey(String from, String to) async {
    final v = _prefs.get(from);
    if (v == null) return;
    if (v is bool) {
      await _prefs.setBool(to, v);
    } else if (v is int) {
      await _prefs.setInt(to, v);
    } else if (v is double) {
      await _prefs.setDouble(to, v);
    } else if (v is String) {
      await _prefs.setString(to, v);
    } else if (v is List<String>) {
      await _prefs.setStringList(to, v);
    } else {
      // Unknown type — shouldn't happen for our 13 keys, but log so we
      // notice if a future suffix is added without the right setter here.
      debugPrint('[SpMigrator] unsupported value type for $from: ${v.runtimeType}');
    }
  }
}
