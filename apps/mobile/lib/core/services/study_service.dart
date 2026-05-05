import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../storage/drift/app_database.dart';
import '../storage/local_database.dart';
import '../storage/local_settings_service.dart';
import 'learning_word_detail.dart';
import 'word_detail_repository.dart';
import 'word_enrichment_service.dart';

/// P3.1 — Local-first study service.
///
/// Write flow: SQLite FIRST → UI feedback → background API sync
/// Read flow: LOCAL cached_words → fallback to API if empty
///
/// P3.3.17: Words are now served from the pre-bundled local cache
/// ([cached_words] drift table, populated from assets/words/book-001.json).
/// No network is needed to get the next word.  API sync still happens in
/// the background so daily-goal / settlement / cloud progress stay updated.
///
/// v3: Multi-wordbook support. When [activeWordbook] ≠ 'book-001', words are
/// served from [word_entries] + [word_book_assignments] (ZK / GK content layer).
/// Example sentences are fetched from [example_sentences] and attached to
/// the returned [Word] in all paths.
class StudyService {
  final ApiClient _apiClient;
  final LocalDatabase _db;
  final AppDatabase _driftDb;
  // Optional injected settings (for testability). If null, reads SharedPreferences.
  final LocalSettingsService? _settings;
  final WordDetailRepository _detailRepo;

  /// Legacy CET-4 book ID — used when activeWordbook is 'book-001'.
  static const String _legacyBookId = 'book-001';

  StudyService({
    required ApiClient apiClient,
    required LocalDatabase db,
    AppDatabase? driftDb,
    LocalSettingsService? settings,
    WordDetailRepository? detailRepo,
  })  : _apiClient = apiClient,
        _db = db,
        _driftDb = driftDb ?? AppDatabase(),
        _settings = settings,
        _detailRepo = detailRepo ??
            WordDetailRepository(
              WordEnrichmentService(driftDb: driftDb ?? AppDatabase()),
            );

  /// Resolve the [WordEnrichment] for [word] (or fetch on cache miss)
  /// and return a [LearningWordDetail] — single-call replacement for
  /// the historical "load Word, then load enrichment separately" flow.
  Future<LearningWordDetail> attachEnrichment(Word word) =>
      _detailRepo.attachEnrichment(word);

  /// Best-effort: warm the enrichment cache for upcoming words. Caller
  /// is expected to obtain [wordTexts] via [peekNextWordTexts]. Failures
  /// are swallowed inside the repository — cache stays clean.
  Future<void> warmUpWordTexts(List<String> wordTexts) =>
      _detailRepo.warmUpWordTexts(wordTexts);

  /// Resolve the currently active wordbook slug.
  Future<String> _activeWordbook() async {
    if (_settings != null) return _settings!.activeWordbook;
    try {
      final prefs = await SharedPreferences.getInstance();
      return LocalSettingsService(prefs).activeWordbook;
    } catch (_) {
      return _legacyBookId;
    }
  }

  /// Get the next word to study.
  ///
  /// Routing:
  ///   activeWordbook == 'book-001' → legacy [cached_words] path (CET-4)
  ///   activeWordbook == 'zk'/'gk'  → [word_entries] + [word_book_assignments]
  ///
  /// In both paths, up to 3 example sentences are fetched from
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

    if (bookSlug == _legacyBookId) {
      // ── Legacy CET-4 path ────────────────────────────────────────────
      final cached =
          await _driftDb.getNextUnstudiedWord(_legacyBookId, allExclude);
      if (cached != null) {
        word = Word(
          wordId: cached.wordId,
          wordText: cached.wordText,
          meaning: cached.meaning,
          phonetic: cached.phonetic,
          bookId: cached.bookId,
          translation: cached.translation,
        );
      }
    } else {
      // ── ZK / GK path ─────────────────────────────────────────────────
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
            .map((e) =>
                WordExample(sense: e.sense, en: e.en, cn: e.cn))
            .toList(),
      );

  /// Resolve full [Word] objects (with examples attached) for today's
  /// "stuck forgot" word_ids — words the user forgot earlier today but
  /// never recovered (no `know` record in word_records). Used by
  /// StudyPage to rehydrate the consolidation queue at session start
  /// so these words can re-appear via Path A / Path C without
  /// counting against the daily-goal cap.
  ///
  /// Routes per word:
  ///   1. cached_words (CET-4) lookup
  ///   2. word_entries (ZK/GK) fallback
  ///   3. silently skip words present in neither (orphan rows from a
  ///      since-removed wordbook or stale data — treat as no-op).
  Future<List<Word>> loadStuckForgotWords() async {
    final ids = await _db.getTodayStuckForgotIds();
    if (ids.isEmpty) return [];
    final result = <Word>[];
    for (final id in ids) {
      Word? word;
      final cached = await _driftDb.getCachedWordById(id);
      if (cached != null) {
        word = Word(
          wordId: cached.wordId,
          wordText: cached.wordText,
          meaning: cached.meaning,
          phonetic: cached.phonetic,
          translation: cached.translation,
          bookId: cached.bookId,
        );
      } else {
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
