import '../api/api_client.dart';
import '../storage/drift/app_database.dart';
import '../storage/repositories/review_record_repository.dart';

/// Need #10 — Local + cloud review attempt history.
///
/// Architecture invariant (mirrors Need #8): the local store NEVER
/// invents acceptance status. Local rows persist offline-friendly raw
/// facts (word_id, reviewed_at, session_id, rating, action_result),
/// flagged as `synced = 0` until the cloud confirms; the cloud is the
/// only authority on what counts as "accepted history".
///
/// FSRS / rewards / settlement are untouched.
///
/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.4): user-scoped via
/// [ReviewRecordRepository]. Construct one ReviewLogService per user;
/// PR-C-α SP-bridge fallback is gone.
class ReviewLogService {
  ReviewLogService({
    required ApiClient apiClient,
    required ReviewRecordRepository repository,
  })  : _apiClient = apiClient,
        _repo = repository;

  /// Convenience constructor when the caller has a userId but no repo.
  factory ReviewLogService.forUser({
    required ApiClient apiClient,
    required AppDatabase driftDb,
    required String userId,
  }) {
    return ReviewLogService(
      apiClient: apiClient,
      repository: ReviewRecordRepository(db: driftDb, userId: userId),
    );
  }

  final ApiClient _apiClient;
  final ReviewRecordRepository _repo;

  /// Insert one local review record. Always returns the new local row id.
  /// Pass [synced] = true only when the caller already got an HTTP 200 from
  /// the cloud (e.g. the per-word `submitReviewAttempt` path that awaits
  /// the response). Otherwise leave the default false — the sync sweeper
  /// will retry.
  Future<int> recordLocal({
    required String wordId,
    required String reviewGroupId,
    required String actionResult,
    String? sessionId,
    int? rating,
    DateTime? reviewedAt,
    bool synced = false,
  }) {
    final ts = (reviewedAt ?? DateTime.now().toUtc()).toIso8601String();
    return _repo.insertRecord(
      reviewGroupId: reviewGroupId,
      wordId: wordId,
      actionResult: actionResult,
      createdAt: ts,
      sessionId: sessionId,
      rating: rating,
      synced: synced ? 1 : 0,
    );
  }

  /// Mark a local row as confirmed by the cloud. Best-effort; missing
  /// rows are silently ignored (e.g. if the row was wiped between submit
  /// and ack). PR-C-β: the WHERE also matches `user_id` so an in-flight
  /// account-switch can't flip the prior user's row.
  Future<void> markSynced(int localId) async {
    await _repo.markSynced(localId);
  }

  /// All local rows for a word, newest first. Includes both synced and
  /// unsynced — the debug page tags them.
  Future<List<ReviewRecord>> getLocalForWord(String wordId, {int limit = 20}) {
    return _repo.listByWordId(wordId, limit: limit);
  }

  /// Pending (unsynced) local rows for a word, newest first.
  Future<List<ReviewRecord>> getPendingForWord(String wordId, {int limit = 20}) {
    return _repo.listPendingByWordId(wordId, limit: limit);
  }

  /// Cloud-accepted history for a word.
  Future<List<WordReviewHistoryItem>> getCloudForWord(
    String wordId, {
    int limit = 20,
  }) {
    return _apiClient.getWordReviewHistory(wordId: wordId, limit: limit);
  }
}
