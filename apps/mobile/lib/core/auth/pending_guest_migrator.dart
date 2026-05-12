/// 需求 23 Phase C PR-C-γ (plan-023-C-v2 §4.6): cross-storage migration
/// of `pending-local-guest` rows to a freshly issued server user_id.
///
/// Scenario:
///   * Day 1: User cold-starts the app with no network. AuthBootstrap
///     fails `/auth/guest`, persists `auth_current_user_id =
///     pending-local-guest`. Drift v13 onUpgrade backfills any existing
///     v12 rows with `user_id = pending-local-guest`. The user studies;
///     new rows go into drift / SQLite tagged with `pending-local-guest`.
///   * Day 2: Network is back. AuthBootstrap reads
///     `pending-local-guest` from SP, calls `/auth/guest`, gets a real
///     `server_guest_id`, persists it. But the rows from Day 1 are still
///     tagged with `pending-local-guest` — they need to be re-tagged so
///     the new user can see their own data.
///
/// This class executes that re-tagging:
///   * 9 user-scoped drift tables get `UPDATE … SET user_id = :to WHERE
///     user_id = :from` in a single transaction.
///   * SP keys of shape `u_<from>_<suffix>` are renamed to
///     `u_<to>_<suffix>` (preserving every supported value type).
///
/// Idempotent: a second run finds no `pending-local-guest` rows and
/// no `u_pending-local-guest_*` keys, so every operation matches 0 rows
/// / 0 keys and is a no-op.
library;

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/drift/app_database.dart';

class PendingGuestMigrator {
  final AppDatabase _db;
  final SharedPreferences _prefs;

  PendingGuestMigrator({
    required AppDatabase db,
    required SharedPreferences prefs,
  })  : _db = db,
        _prefs = prefs;

  /// The 9 user-scoped drift tables from PR-C-α v13 schema. Order
  /// doesn't matter — each UPDATE is independent and scoped by
  /// `user_id`. Kept in the same order as `_v13UserScopedPartition`
  /// for readability.
  static const List<String> userScopedTables = [
    'word_records',
    'wordbook_progress',
    'daily_checkins',
    'custom_wordbooks',
    'vocabulary_notebook',
    'card_states',
    'review_logs',
    'sessions',
    'review_records',
  ];

  /// Migrate every row / SP key from [from] → [to].
  ///
  /// Refuses to run when [from] == [to] (would be a no-op write storm)
  /// or when either id is empty (defensive — empty user_id should not
  /// exist in practice; if it does, we don't want to claim ownership
  /// of orphan rows).
  Future<MigrationOutcome> migrate({
    required String from,
    required String to,
  }) async {
    if (from.isEmpty || to.isEmpty) {
      debugPrint('[PendingGuestMigrator] refusing: empty id ($from → $to)');
      return const MigrationOutcome(skipped: true);
    }
    if (from == to) {
      // Common path on app startup where current user is still
      // pending-local-guest (offline) — nothing to migrate.
      return const MigrationOutcome(skipped: true);
    }

    int driftRowsAffected = 0;
    int spKeysRenamed = 0;

    try {
      // 1. drift: 9 tables UPDATE in a single transaction. We use
      //    customUpdate (not customStatement) because it returns the
      //    affected-row count drift's underlying executor exposes —
      //    keeps the [MigrationOutcome] honest for the main.dart log.
      await _db.transaction(() async {
        for (final table in userScopedTables) {
          // sqlite_master probe to skip tables that don't exist (test
          // environments where only a subset of v13 tables are
          // pre-created — the migration_test fixtures, for example).
          if (!await _tableExists(table)) continue;

          final affected = await _db.customUpdate(
            'UPDATE $table SET user_id = ? WHERE user_id = ?',
            variables: [Variable.withString(to), Variable.withString(from)],
          );
          driftRowsAffected += affected;
        }
      });

      // 2. SP namespace rename. Walk the entire keyspace once; for any
      //    key starting with `u_<from>_`, copy its value to the
      //    equivalent `u_<to>_<suffix>` key (if not already there) and
      //    delete the old key.
      final fromPrefix = 'u_${from}_';
      final toPrefix = 'u_${to}_';
      final candidates = _prefs
          .getKeys()
          .where((k) => k.startsWith(fromPrefix))
          .toList();
      for (final oldKey in candidates) {
        final suffix = oldKey.substring(fromPrefix.length);
        final newKey = '$toPrefix$suffix';
        if (!_prefs.containsKey(newKey)) {
          await _copyKey(oldKey, newKey);
        }
        await _prefs.remove(oldKey);
        spKeysRenamed += 1;
      }

      return MigrationOutcome(
        driftRowsAffected: driftRowsAffected,
        spKeysRenamed: spKeysRenamed,
      );
    } catch (e, st) {
      // Migration is best-effort. A failure here leaves the system in
      // a half-migrated state which is still safe (data isn't lost,
      // just split between two user_id buckets). The next launch
      // re-runs migration — see main.dart wiring.
      debugPrint('[PendingGuestMigrator] migration failed: $e\n$st');
      return MigrationOutcome(
        driftRowsAffected: driftRowsAffected,
        spKeysRenamed: spKeysRenamed,
        error: e,
      );
    }
  }

  /// True if [name] exists in `sqlite_master` for the bound drift
  /// connection.
  Future<bool> _tableExists(String name) async {
    final rows = await _db.customSelect(
      "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
      variables: [Variable.withString(name)],
    ).get();
    return rows.isNotEmpty;
  }

  /// Copy whatever-typed value is under [from] into [to]. Mirrors the
  /// type-probing logic in [SpMigrator] — the two migrators move
  /// different namespaces (flat → u_<userId>_*) vs (u_a_* → u_b_*) but
  /// share the same set of SP value types in practice.
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
      debugPrint(
        '[PendingGuestMigrator] unsupported value type for $from: '
        '${v.runtimeType}',
      );
    }
  }
}

/// Result of a [PendingGuestMigrator.migrate] call. Surfaced to
/// callers so main.dart can log how many rows actually moved (useful
/// for diagnosing whether the migration found anything to do on a
/// given launch).
class MigrationOutcome {
  final int driftRowsAffected;
  final int spKeysRenamed;
  final bool skipped;
  final Object? error;

  const MigrationOutcome({
    this.driftRowsAffected = 0,
    this.spKeysRenamed = 0,
    this.skipped = false,
    this.error,
  });

  bool get isNoop =>
      skipped || (driftRowsAffected == 0 && spKeysRenamed == 0 && error == null);

  bool get hasError => error != null;

  @override
  String toString() => 'MigrationOutcome('
      'drift=$driftRowsAffected, sp=$spKeysRenamed, '
      'skipped=$skipped, error=$error)';
}
