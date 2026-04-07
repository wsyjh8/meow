import '../api/api_client.dart';
import '../storage/local_database.dart';

/// P3.1 — Local-first study service.
///
/// Write flow: SQLite FIRST → UI feedback → background API sync
/// Read flow: API for next word → cache locally
///
/// This service sits between StudyPage and both LocalDatabase + ApiClient.
/// The user sees immediate feedback; API sync happens in background.
class StudyService {
  final ApiClient _apiClient;
  final LocalDatabase _db;

  StudyService({required ApiClient apiClient, required LocalDatabase db})
      : _apiClient = apiClient,
        _db = db;

  /// Get the next word to study.
  ///
  /// 1. Try API first (it has the full word pool)
  /// 2. If API fails, return null (no offline word pool yet)
  Future<Word?> getNextWord() async {
    try {
      // Get mastered word IDs from local SQLite
      final masteredIds = await _db.getMasteredWordIds();

      // Get next word from API
      final word = await _apiClient.getNextNewWord();

      if (word == null) {
        // API says no more words — but check if local has unmastered words
        // that the API might not know about (e.g., forgot words not yet synced)
        return null;
      }

      // If this word is already mastered locally (but API doesn't know yet),
      // skip it and try again
      if (masteredIds.contains(word.wordId)) {
        // This shouldn't happen normally, but defensive check
        return word; // Let user see it anyway — API is the word pool authority
      }

      return word;
    } catch (e) {
      // API unavailable — no offline word pool, return null
      return null;
    }
  }

  /// Submit a study attempt — LOCAL FIRST.
  ///
  /// 1. Write to SQLite immediately (synced=0)
  /// 2. Return result immediately (UI can proceed)
  /// 3. Try API sync in background (fire-and-forget)
  Future<LocalStudyResult> submitStudyAttempt({
    required String wordId,
    required String bookId,
    required String studyType,
    required String actionResult,
  }) async {
    // Step 1: Write to SQLite FIRST
    final localId = await _db.insertWordRecord(
      wordId: wordId,
      bookId: bookId,
      studyType: studyType,
      actionResult: actionResult,
    );

    // Step 2: Return immediate result (don't wait for API)
    final result = LocalStudyResult(
      success: true,
      wordId: wordId,
      actionResult: actionResult,
      localId: localId,
    );

    // Step 3: Background API sync (fire-and-forget)
    _syncToApiInBackground(
      wordId: wordId,
      bookId: bookId,
      studyType: studyType,
      actionResult: actionResult,
      localId: localId,
    );

    return result;
  }

  /// Try to sync a single record to the API in background.
  void _syncToApiInBackground({
    required String wordId,
    required String bookId,
    required String studyType,
    required String actionResult,
    required int localId,
  }) async {
    try {
      final idempotencyKey = 'study-local-$localId-${DateTime.now().millisecondsSinceEpoch}';
      await _apiClient.submitStudyAttempt(
        wordId: wordId,
        bookId: bookId,
        studyType: studyType,
        actionResult: actionResult,
        idempotencyKey: idempotencyKey,
      );
      // API succeeded — mark as synced
      await _db.markSynced(localId);
    } catch (_) {
      // API failed — record stays synced=0, will be retried later or included in backup
    }
  }

  /// Sync all pending (unsynced) records to the API.
  /// Called on app start or manually.
  Future<int> syncPendingAttempts() async {
    final unsynced = await _db.getUnsyncedRecords();
    int syncedCount = 0;

    for (final record in unsynced) {
      try {
        final idempotencyKey = 'study-sync-${record['id']}-${DateTime.now().millisecondsSinceEpoch}';
        await _apiClient.submitStudyAttempt(
          wordId: record['word_id'] as String,
          bookId: record['book_id'] as String,
          studyType: record['study_type'] as String,
          actionResult: record['action_result'] as String,
          idempotencyKey: idempotencyKey,
        );
        await _db.markSynced(record['id'] as int);
        syncedCount++;
      } catch (_) {
        // Stop on first failure (will retry next time)
        break;
      }
    }

    return syncedCount;
  }

  void dispose() {
    _apiClient.dispose();
  }
}

/// Result of a local-first study submission.
/// This returns IMMEDIATELY after SQLite write — does not wait for API.
class LocalStudyResult {
  final bool success;
  final String wordId;
  final String actionResult;
  final int localId;

  const LocalStudyResult({
    required this.success,
    required this.wordId,
    required this.actionResult,
    required this.localId,
  });
}
