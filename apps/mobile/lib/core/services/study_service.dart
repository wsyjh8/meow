import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../storage/drift/app_database.dart';
import '../storage/local_database.dart';
import '../storage/local_settings_service.dart';

/// P3.1 — Local-first study service.
///
/// Write flow: SQLite FIRST → UI feedback → background API sync
/// Read flow: LOCAL word_entries → fallback to API if empty
///
/// v0.3.0 P1: All books (CET-4 / ZK / GK) flow through the unified
/// `word_entries` + `word_book_assignments` content layer (populated by
/// WordbookLoader from assets/words/*.json). The legacy `cached_words`
/// path is gone, and so is the `if (bookSlug == 'book-001')` branch.
/// No network is needed to get the next word; API sync still happens in
/// the background so daily-goal / settlement / cloud progress stay updated.
class StudyService {
  final ApiClient _apiClient;
  final LocalDatabase _db;
  final AppDatabase _driftDb;
  // Optional injected settings (for testability). If null, reads SharedPreferences.
  final LocalSettingsService? _settings;

  StudyService({
    required ApiClient apiClient,
    required LocalDatabase db,
    AppDatabase? driftDb,
    LocalSettingsService? settings,
  })  : _apiClient = apiClient,
        _db = db,
        _driftDb = driftDb ?? AppDatabase(),
        _settings = settings;

  /// Default wordbook when settings unavailable. v0.3.0 P1: still 'book-001'
  /// for backwards-compat (existing dev installs), but it's now just a
  /// regular bookSlug — no special legacy treatment.
  static const String _defaultBookSlug = 'book-001';

  /// Resolve the currently active wordbook slug.
  Future<String> _activeWordbook() async {
    if (_settings != null) return _settings!.activeWordbook;
    try {
      final prefs = await SharedPreferences.getInstance();
      return LocalSettingsService(prefs).activeWordbook;
    } catch (_) {
      return _defaultBookSlug;
    }
  }

  /// Get the next word to study.
  ///
  /// v0.3.0 P1: unified path through `word_entries` + `word_book_assignments`
  /// for ALL books (CET-4 / ZK / GK). Up to 3 example sentences are fetched from
  /// [example_sentences] and attached to [Word.examples] if available.
  ///
  /// Fallback to API only when local cache is empty (edge-case / fresh install).
  Future<Word?> getNextWord({Set<String> extraExclude = const {}}) async {
    // DB operations are NOT wrapped in a blanket catch.
    // A real DB error (e.g. closed connection) propagates to the caller's
    // catch block (StudyPage._loadNextWord), which shows an error state
    // instead of falsely displaying the "all done" completion screen.

    // 1. Get mastered word IDs from local SQLite (word_records)
    final bookSlug = await _activeWordbook();
    final masteredIds = await _db.getMasteredWordIds();

    // 2. Merge mastered + session-seen exclusions
    final allExclude = masteredIds.union(extraExclude);

    Word? word;

    // v0.3.0 P1: unified path through word_entries / word_book_assignments
    // for ALL books (CET-4 / ZK / GK). The legacy `getNextUnstudiedWord`
    // (cached_words) branch is gone.
    final entry =
        await _driftDb.getNextWordFromWordbook(bookSlug, allExclude);
    if (entry != null) {
      word = Word(
        wordId: entry.wordId,
        wordText: entry.wordText,
        meaning: entry.meaning,
        phonetic: entry.phonetic,
        bookId: bookSlug,
        translation: entry.translation,
        definition: entry.definition,
        frequencyRank: entry.frequencyRank,
        wordForms: entry.wordForms,
      );
    }

    // 3. Attach examples (both paths — best-effort, silently ignored on failure)
    //
    // Need #11 follow-up: lookup is by word_text rather than word_id, so
    // CET-4 'ability' inherits ZK / GK example sentences for the same
    // English word. Falls back to the legacy word_id query when nothing
    // is found via word_text (covers the unusual case where a word has
    // examples bound only to its specific book id).
    if (word != null) {
      try {
        var exRows =
            await _driftDb.getExamplesForWordText(word.wordText, limit: 3);
        if (exRows.isEmpty) {
          exRows = await _driftDb.getExamplesForWord(word.wordId, limit: 3);
        }
        if (exRows.isNotEmpty) {
          word = _withExamples(word, exRows);
        }
      } catch (_) {}
      return word;
    }

    // 4. No local words — try API. Network failures return null (not a DB
    //    error, so don't propagate — "no network + no local words" is treated
    //    as "nothing available right now", not a crash-worthy error).
    try {
      return await _apiClient.getNextNewWord();
    } catch (_) {
      return null;
    }
  }

  /// Rebuild a [Word] with example sentences attached.
  Word _withExamples(Word w, List<ExampleSentence> rows) => Word(
        wordId: w.wordId,
        wordText: w.wordText,
        meaning: w.meaning,
        phonetic: w.phonetic,
        bookId: w.bookId,
        translation: w.translation,
        definition: w.definition,
        difficultyLevel: w.difficultyLevel,
        isCore: w.isCore,
        tags: w.tags,
        frequencyRank: w.frequencyRank,
        wordForms: w.wordForms,
        examples: rows
            .map((e) => WordExample(
                  sense: e.sense,
                  en: e.en,
                  cn: e.cn,
                  stableId: e.stableId, // v0.3.0 P0: propagate to UI for audio lookup
                ))
            .toList(),
      );

  /// Resolve full [Word] objects (with examples attached) for today's
  /// "stuck forgot" word_ids — words the user forgot earlier today but
  /// never recovered (no `know` record in word_records). Used by
  /// StudyPage to rehydrate the consolidation queue at session start
  /// so these words can re-appear via Path A / Path C without
  /// counting against the daily-goal cap.
  ///
  /// v0.3.0 P1: cached_words / getCachedWordById removed. CET-4 / ZK / GK
  /// all flow through word_entries (loaded by WordbookLoader from bundled
  /// assets), so a single lookup suffices.
  ///
  /// Routes per word:
  ///   1. word_entries (any book) lookup
  ///   2. silently skip words missing from word_entries (orphan rows from
  ///      a since-removed wordbook or stale data — treat as no-op).
  Future<List<Word>> loadStuckForgotWords() async {
    final ids = await _db.getTodayStuckForgotIds();
    if (ids.isEmpty) return [];
    final result = <Word>[];
    for (final id in ids) {
      Word? word;
      final entry = await _driftDb.getWordEntryById(id);
      if (entry != null) {
        word = Word(
          wordId: entry.wordId,
          wordText: entry.wordText,
          meaning: entry.meaning,
          phonetic: entry.phonetic,
          translation: entry.translation,
          definition: entry.definition,
          frequencyRank: entry.frequencyRank,
          wordForms: entry.wordForms,
          bookId: 'review',
        );
      }
      if (word == null) continue;
      Word resolved = word;
      try {
        var exRows = await _driftDb
            .getExamplesForWordText(resolved.wordText, limit: 3);
        if (exRows.isEmpty) {
          exRows =
              await _driftDb.getExamplesForWord(resolved.wordId, limit: 3);
        }
        if (exRows.isNotEmpty) resolved = _withExamples(resolved, exRows);
      } catch (_) {}
      result.add(resolved);
    }
    return result;
  }

  /// Write a local-only `know` record without triggering cloud sync.
  /// Used by StudyPage when a word exits the consolidation queue
  /// (consecutive 2 know's) so future sessions know the word was
  /// recovered today and don't re-seed it back into consolidation.
  /// Deliberately bypasses [_syncToApiInBackground] — consolidation
  /// recoveries are local-only by design (no cloud attempt history,
  /// no FSRS update, see session_consolidation_v1 spec).
  Future<void> recordLocalConsolidationRecovery({
    required String wordId,
    required String bookId,
    String? sessionId,
  }) async {
    await _db.insertWordRecord(
      wordId: wordId,
      bookId: bookId,
      studyType: 'new',
      actionResult: 'know',
      sessionId: sessionId,
    );
  }

  /// Peek at the word_text values of the next [count] unstudied words.
  ///
  /// Used by the study page to prefetch pronunciation audio ahead of time.
  /// Does NOT consume or mark any words — purely a read-ahead.
  Future<List<String>> peekNextWordTexts(
    int count, {
    Set<String> extraExclude = const {},
  }) async {
    final bookSlug = await _activeWordbook();
    final masteredIds = await _db.getMasteredWordIds();
    final allExclude = masteredIds.union(extraExclude);
    return _driftDb.peekNextWordTexts(bookSlug, allExclude, count);
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
    String? sessionId,
  }) async {
    // Step 1: Write to SQLite FIRST
    final localId = await _db.insertWordRecord(
      wordId: wordId,
      bookId: bookId,
      studyType: studyType,
      actionResult: actionResult,
      sessionId: sessionId,
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
      sessionId: sessionId,
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
    String? sessionId,
  }) async {
    try {
      final idempotencyKey = 'study-local-$localId-${DateTime.now().millisecondsSinceEpoch}';
      await _apiClient.submitStudyAttempt(
        wordId: wordId,
        bookId: bookId,
        studyType: studyType,
        actionResult: actionResult,
        idempotencyKey: idempotencyKey,
        sessionId: sessionId,
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
          sessionId: record['session_id'] as String?,
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
