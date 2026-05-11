/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.4): per-user repository for
/// the `sessions` drift table.
///
/// Need #8's session id is a UUID and reused as the server session id;
/// the legacy SessionStore code already relied on its uniqueness across
/// users, but PR-C-β still scopes every read/write by user_id so a
/// future bug (e.g. uuid collision, or a guest-bind row migration)
/// cannot let A's `synced=0` row resurface during B's sync pass.
library;

import 'package:drift/drift.dart';

import '../drift/app_database.dart';

class SessionRepository {
  final AppDatabase _db;
  final String userId;

  SessionRepository({required AppDatabase db, required this.userId})
      : _db = db;

  Future<void> insertSession({
    required String id,
    required String kind,
    required String startedAt,
    int sessionMinutesTarget = 15,
  }) async {
    await _db.into(_db.sessions).insert(
          SessionsCompanion.insert(
            id: id,
            userId: userId,
            kind: kind,
            startedAt: startedAt,
            sessionMinutesTarget: Value(sessionMinutesTarget),
          ),
        );
  }

  /// Find this user's session by id. Null if not found OR if it belongs
  /// to another user (cross-user leak guard).
  Future<Session?> findById(String id) {
    return (_db.select(_db.sessions)
          ..where((t) => t.userId.equals(userId) & t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Apply [updates] to this user's session with matching id. Returns
  /// rows affected — when 0, the caller hit a cross-user write attempt
  /// (we silently no-op rather than throw; PR-C-β considers this
  /// `markSynced`-style defensive behavior, plan §4.1 review 1 P2).
  Future<int> updateById(String id, SessionsCompanion updates) {
    return (_db.update(_db.sessions)
          ..where((t) => t.userId.equals(userId) & t.id.equals(id)))
        .write(updates);
  }

  /// Rows for this user with `synced < target` — used by
  /// SessionSyncService to pick up unsynced sessions on app resume.
  Future<List<Session>> listUnsynced({int syncedBelow = 2}) {
    return (_db.select(_db.sessions)
          ..where((t) =>
              t.userId.equals(userId) & t.synced.isSmallerThanValue(syncedBelow))
          ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
        .get();
  }
}
