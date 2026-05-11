import 'package:drift/drift.dart';

import '../api/api_client.dart';
import '../auth/auth_storage.dart';
import '../storage/drift/app_database.dart';

/// Need #10 — Local + cloud review attempt history.
///
/// Architecture invariant (mirrors Need #8): the local store NEVER
/// invents acceptance status. Local rows persist offline-friendly raw
/// facts (word_id, reviewed_at, session_id, rating, action_result),
/// flagged as `synced = 0` until the cloud confirms; the cloud is the
/// only authority on what counts as "accepted history".
///
/// FSRS / rewards / settlement are untouched.
class ReviewLogService {
  ReviewLogService({required ApiClient apiClient, AppDatabase? driftDb})
      : _apiClient = apiClient,
        _db = driftDb ?? AppDatabase();

  final ApiClient _apiClient;
  final AppDatabase _db;

  /// Insert one local review record. Always returns the new local row id.
  /// Pass [synced] = 1 only when the caller already got an HTTP 200 from
  /// the cloud (e.g. the per-word `submitReviewAttempt` path that awaits
  /// the response). Otherwise leave the default 0 — the sync sweeper
  /// will retry.
  Future<int> recordLocal({
    required String wordId,
    required String reviewGroupId,
    required String actionResult,
    String? sessionId,
    int? rating,
    DateTime? reviewedAt,
    bool synced = false,
  }) async {
    final ts = (reviewedAt ?? DateTime.now().toUtc()).toIso8601String();
    // PR-C-α transitional bridge — PR-C-β will hoist userId into the
    // ReviewLogService constructor (plan-023-C-v2 §4.4 repository pattern).
    final userId = await AuthStorage.readBoundUserIdOrPlaceholder();
    return _db.into(_db.reviewRecords).insert(
          ReviewRecordsCompanion.insert(
            userId: userId,
            reviewGroupId: reviewGroupId,
            wordId: wordId,
            actionResult: actionResult,
            createdAt: ts,
            sessionId: Value(sessionId),
            rating: Value(rating),
            synced: Value(synced ? 1 : 0),
          ),
        );
  }

  /// Mark a local row as confirmed by the cloud. Best-effort; missing
  /// rows are silently ignored (e.g. if the row was wiped between submit
  /// and ack).
  Future<void> markSynced(int localId) async {
    await (_db.update(_db.reviewRecords)..where((t) => t.id.equals(localId)))
        .write(const ReviewRecordsCompanion(synced: Value(1)));
  }

  /// All local rows for a word, newest first. Includes both synced and
  /// unsynced — the debug page tags them.
  Future<List<ReviewRecord>> getLocalForWord(String wordId, {int limit = 20}) {
    return (_db.select(_db.reviewRecords)
          ..where((t) => t.wordId.equals(wordId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Pending (unsynced) local rows for a word, newest first.
  Future<List<ReviewRecord>> getPendingForWord(String wordId, {int limit = 20}) {
    return (_db.select(_db.reviewRecords)
          ..where((t) =>
              t.wordId.equals(wordId) & t.synced.isSmallerThanValue(1))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Cloud-accepted history for a word.
  Future<List<WordReviewHistoryItem>> getCloudForWord(
    String wordId, {
    int limit = 20,
  }) {
    return _apiClient.getWordReviewHistory(wordId: wordId, limit: limit);
  }
}
