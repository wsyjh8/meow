/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.4): per-user repository for
/// the `review_records` drift table.
///
/// review_records is local-first attempt history that backs the
/// per-word "复习历史" debug page; cloud is authoritative for what counts
/// as accepted. PR-C-β scopes every read by userId and forces every
/// markSynced/update to also match `user_id`, so an in-flight
/// account-switch can't move the wrong row to synced=1.
library;

import 'package:drift/drift.dart';

import '../drift/app_database.dart';

class ReviewRecordRepository {
  final AppDatabase _db;
  final String userId;

  ReviewRecordRepository({required AppDatabase db, required this.userId})
      : _db = db;

  /// Insert one local review record for this user. Returns new row id.
  Future<int> insertRecord({
    required String reviewGroupId,
    required String wordId,
    required String actionResult,
    required String createdAt,
    String? sessionId,
    int? rating,
    int synced = 0,
  }) {
    return _db.into(_db.reviewRecords).insert(
          ReviewRecordsCompanion.insert(
            userId: userId,
            reviewGroupId: reviewGroupId,
            wordId: wordId,
            actionResult: actionResult,
            createdAt: createdAt,
            sessionId: Value(sessionId),
            rating: Value(rating),
            synced: Value(synced),
          ),
        );
  }

  /// Best-effort mark synced by id, defensive WHERE on user_id (plan
  /// §4.1 review 1 P2): if an account-switch happens while the network
  /// reply is in-flight, the new user's repository won't accidentally
  /// flip the prior user's row.
  Future<int> markSynced(int localId, {int synced = 1}) {
    return (_db.update(_db.reviewRecords)
          ..where((t) => t.userId.equals(userId) & t.id.equals(localId)))
        .write(ReviewRecordsCompanion(synced: Value(synced)));
  }

  /// All of this user's records for [wordId], newest first.
  Future<List<ReviewRecord>> listByWordId(
    String wordId, {
    int limit = 20,
  }) {
    return (_db.select(_db.reviewRecords)
          ..where((t) => t.userId.equals(userId) & t.wordId.equals(wordId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Pending (`synced=0`) records for [wordId], newest first.
  Future<List<ReviewRecord>> listPendingByWordId(
    String wordId, {
    int limit = 20,
  }) {
    return (_db.select(_db.reviewRecords)
          ..where((t) =>
              t.userId.equals(userId) &
              t.wordId.equals(wordId) &
              t.synced.isSmallerThanValue(1))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }
}
