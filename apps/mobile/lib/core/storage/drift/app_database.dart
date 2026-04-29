import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';

import 'tables/legacy_tables.dart';
import 'tables/fsrs_tables.dart';

part 'app_database.g.dart';

/// Main drift database for the app.
///
/// Schema history:
///   v1 (raw sqflite): word_records, wordbook_progress, daily_checkins,
///                     custom_wordbooks, vocabulary_notebook
///   v2 (drift):       + card_states, review_logs, cached_words
///   v3:               + preset_wordbooks, word_entries,
///                       word_book_assignments, example_sentences
///   v4:               content layer tables rebuilt with:
///                       - preset_wordbooks.content_version
///                       - word_entries.cached_at → imported_at
///                       - word_book_assignments.source_key
///                       - example_sentences unique index on (word_id, sort_order)
@DriftDatabase(tables: [
  // Legacy tables (v1, migrated from raw sqflite)
  WordRecords,
  WordbookProgress,
  DailyCheckins,
  CustomWordbooks,
  VocabularyNotebook,
  // FSRS tables (v2, new)
  CardStates,
  ReviewLogs,
  CachedWords,
  // Content layer (v3, wordbooks + examples)
  PresetWordbooks,
  WordEntries,
  WordBookAssignments,
  ExampleSentences,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing: accept any QueryExecutor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // Fresh install: drift creates all 12 tables from definitions.
          await m.createAll();
          // Manually create indexes for legacy tables
          // (drift @TableIndex handles FSRS table indexes automatically)
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_wr_word_id ON word_records(word_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_wr_synced ON word_records(synced)');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Upgrading from raw sqflite v1:
            // The 5 legacy tables already exist in the database file.
            // Only create the 3 new FSRS tables + their indexes.
            await m.createTable(cardStates);
            await m.createTable(reviewLogs);
            await m.createTable(cachedWords);
            // Note: @TableIndex annotations on CardStates/ReviewLogs
            // generate indexes in createTable automatically.
          }
          if (from < 3) {
            // v3: add the 4 content-layer tables.
            await m.createTable(presetWordbooks);
            await m.createTable(wordEntries);
            await m.createTable(wordBookAssignments);
            await m.createTable(exampleSentences);
          }
          if (from < 4) {
            // v4: content layer schema updated (asset-derived, no user data).
            //   - preset_wordbooks gains content_version
            //   - word_entries: cached_at → imported_at
            //   - word_book_assignments gains source_key
            //   - example_sentences gains UNIQUE index on (word_id, sort_order)
            // Safe to DROP+CREATE: all 4 tables are reloaded from bundled assets on startup.
            await customStatement('DROP TABLE IF EXISTS example_sentences');
            await customStatement('DROP TABLE IF EXISTS word_book_assignments');
            await customStatement('DROP TABLE IF EXISTS word_entries');
            await customStatement('DROP TABLE IF EXISTS preset_wordbooks');
            await m.createTable(presetWordbooks);
            await m.createTable(wordEntries);
            await m.createTable(wordBookAssignments);
            await m.createTable(exampleSentences);
          }
        },
      );

  /// Return the next word in [bookId] that the user has not yet studied.
  ///
  /// [excludeWordIds] — word IDs already mastered (from [word_records]);
  ///   these are skipped so the user doesn't see the same word twice.
  ///
  /// Words are served in [sort_order] ASC (CSV import order ≈ frequency order).
  /// Returns null if all words have been mastered or the cache is empty.
  Future<CachedWord?> getNextUnstudiedWord(
    String bookId,
    Set<String> excludeWordIds,
  ) async {
    if (excludeWordIds.isEmpty) {
      return (select(cachedWords)
            ..where((t) => t.bookId.equals(bookId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])
            ..limit(1))
          .getSingleOrNull();
    }
    // NOT IN with raw SQL — safe for up to a few thousand IDs.
    final placeholders = excludeWordIds.map((_) => '?').join(', ');
    final rows = await customSelect(
      'SELECT * FROM cached_words WHERE book_id = ? AND word_id NOT IN ($placeholders) ORDER BY sort_order ASC LIMIT 1',
      variables: [
        Variable.withString(bookId),
        ...excludeWordIds.map(Variable.withString),
      ],
      readsFrom: {cachedWords},
    ).get();
    if (rows.isEmpty) return null;
    final r = rows.first;
    return CachedWord(
      wordId: r.read<String>('word_id'),
      bookId: r.read<String>('book_id'),
      wordText: r.read<String>('word_text'),
      meaning: r.read<String>('meaning'),
      phonetic: r.readNullable<String>('phonetic'),
      translation: r.readNullable<String>('translation'),
      frequencyRank: r.read<int>('frequency_rank'),
      sortOrder: r.read<int>('sort_order'),
      cachedAt: r.read<int>('cached_at'),
    );
  }

  /// Return the next word in [bookSlug] from [word_entries] + [word_book_assignments]
  /// that the user has not yet studied.
  ///
  /// Used when [activeWordbook] is 'zk' or 'gk' (i.e. not the legacy 'book-001').
  /// [excludeWordIds] — mastered + session-seen word IDs to skip.
  /// Returns null if all words have been studied or the wordbook is empty.
  Future<WordEntry?> getNextWordFromWordbook(
    String bookSlug,
    Set<String> excludeWordIds,
  ) async {
    if (excludeWordIds.isEmpty) {
      final rows = await customSelect(
        'SELECT we.* FROM word_entries we '
        'JOIN word_book_assignments wba ON we.word_id = wba.word_id '
        'WHERE wba.book_slug = ? '
        'ORDER BY wba.sort_order ASC LIMIT 1',
        variables: [Variable.withString(bookSlug)],
        readsFrom: {wordEntries, wordBookAssignments},
      ).get();
      if (rows.isEmpty) return null;
      return _wordEntryFromRow(rows.first);
    }
    final placeholders = excludeWordIds.map((_) => '?').join(', ');
    final rows = await customSelect(
      'SELECT we.* FROM word_entries we '
      'JOIN word_book_assignments wba ON we.word_id = wba.word_id '
      'WHERE wba.book_slug = ? AND we.word_id NOT IN ($placeholders) '
      'ORDER BY wba.sort_order ASC LIMIT 1',
      variables: [
        Variable.withString(bookSlug),
        ...excludeWordIds.map(Variable.withString),
      ],
      readsFrom: {wordEntries, wordBookAssignments},
    ).get();
    if (rows.isEmpty) return null;
    return _wordEntryFromRow(rows.first);
  }

  WordEntry _wordEntryFromRow(QueryRow r) => WordEntry(
        wordId: r.read<String>('word_id'),
        wordText: r.read<String>('word_text'),
        phonetic: r.readNullable<String>('phonetic'),
        meaning: r.read<String>('meaning'),
        translation: r.readNullable<String>('translation'),
        definition: r.readNullable<String>('definition'),
        frequencyRank: r.read<int>('frequency_rank'),
        wordForms: r.readNullable<String>('word_forms'),
        importedAt: r.read<int>('imported_at'),
      );

  /// Return all preset wordbooks ordered by [sort_order] ASC.
  ///
  /// Does NOT include 'book-001' (CET-4) — that book is loaded via [AssetWordLoader]
  /// into [cached_words] and is not represented in [preset_wordbooks].
  Future<List<PresetWordbook>> getAllPresetWordbooks() {
    return (select(presetWordbooks)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])
    ).get();
  }

  /// Return all word IDs belonging to [bookSlug].
  ///
  /// For 'book-001' (CET-4): reads [cached_words.word_id].
  /// For ZK / GK: reads [word_book_assignments.word_id].
  ///
  /// Used by the home page to intersect with mastered IDs (from the sqflite
  /// [word_records] table) to compute per-book mastered word count.
  Future<Set<String>> getWordIdsForBook(String bookSlug) async {
    if (bookSlug == 'book-001') {
      final rows = await customSelect(
        'SELECT word_id FROM cached_words WHERE book_id = ?',
        variables: [Variable.withString(bookSlug)],
        readsFrom: {cachedWords},
      ).get();
      return rows.map((r) => r.read<String>('word_id')).toSet();
    }
    final rows = await customSelect(
      'SELECT word_id FROM word_book_assignments WHERE book_slug = ?',
      variables: [Variable.withString(bookSlug)],
      readsFrom: {wordBookAssignments},
    ).get();
    return rows.map((r) => r.read<String>('word_id')).toSet();
  }

  /// Count total words available in [bookSlug].
  ///
  /// For legacy 'book-001' (CET-4): counts rows in [cached_words].
  /// For ZK / GK slugs: counts rows in [word_book_assignments].
  Future<int> countWordsInBook(String bookSlug) async {
    if (bookSlug == 'book-001') {
      final r = await customSelect(
        'SELECT COUNT(*) AS cnt FROM cached_words WHERE book_id = ?',
        variables: [Variable.withString(bookSlug)],
        readsFrom: {cachedWords},
      ).getSingle();
      return r.read<int>('cnt');
    }
    final r = await customSelect(
      'SELECT COUNT(*) AS cnt FROM word_book_assignments WHERE book_slug = ?',
      variables: [Variable.withString(bookSlug)],
      readsFrom: {wordBookAssignments},
    ).getSingle();
    return r.read<int>('cnt');
  }

  /// Look up a single [WordEntry] by [wordId] (ZK / GK content layer).
  /// Returns null if not found (CET-4 words live in [cached_words] instead).
  Future<WordEntry?> getWordEntryById(String wordId) {
    return (select(wordEntries)..where((t) => t.wordId.equals(wordId)))
        .getSingleOrNull();
  }

  /// Look up a single [CachedWord] by [wordId] (CET-4 / legacy path).
  /// Returns null if not found.
  Future<CachedWord?> getCachedWordById(String wordId) {
    return (select(cachedWords)..where((t) => t.wordId.equals(wordId)))
        .getSingleOrNull();
  }

  /// Return up to [limit] example sentences for [wordId] from [example_sentences],
  /// ordered by sort_order ASC.
  Future<List<ExampleSentence>> getExamplesForWord(
    String wordId, {
    int limit = 3,
  }) async {
    final rows = await customSelect(
      'SELECT * FROM example_sentences WHERE word_id = ? '
      'ORDER BY sort_order ASC LIMIT $limit',
      variables: [Variable.withString(wordId)],
      readsFrom: {exampleSentences},
    ).get();
    return rows
        .map((r) => ExampleSentence(
              id: r.read<int>('id'),
              wordId: r.read<String>('word_id'),
              sense: r.read<String>('sense'),
              en: r.read<String>('en'),
              cn: r.read<String>('cn'),
              sortOrder: r.read<int>('sort_order'),
            ))
        .toList();
  }

  /// Peek at the next [limit] unstudied word_text values in [bookSlug].
  ///
  /// Same ordering as [getNextUnstudiedWord] / [getNextWordFromWordbook]
  /// but returns multiple word texts (for pronunciation prefetch).
  Future<List<String>> peekNextWordTexts(
    String bookSlug,
    Set<String> excludeWordIds,
    int limit,
  ) async {
    if (bookSlug == 'book-001') {
      if (excludeWordIds.isEmpty) {
        final rows = await customSelect(
          'SELECT word_text FROM cached_words WHERE book_id = ? '
          'ORDER BY sort_order ASC LIMIT $limit',
          variables: [Variable.withString(bookSlug)],
          readsFrom: {cachedWords},
        ).get();
        return rows.map((r) => r.read<String>('word_text')).toList();
      }
      final ph = excludeWordIds.map((_) => '?').join(', ');
      final rows = await customSelect(
        'SELECT word_text FROM cached_words '
        'WHERE book_id = ? AND word_id NOT IN ($ph) '
        'ORDER BY sort_order ASC LIMIT $limit',
        variables: [
          Variable.withString(bookSlug),
          ...excludeWordIds.map(Variable.withString),
        ],
        readsFrom: {cachedWords},
      ).get();
      return rows.map((r) => r.read<String>('word_text')).toList();
    }
    // ZK / GK
    if (excludeWordIds.isEmpty) {
      final rows = await customSelect(
        'SELECT we.word_text FROM word_entries we '
        'JOIN word_book_assignments wba ON we.word_id = wba.word_id '
        'WHERE wba.book_slug = ? '
        'ORDER BY wba.sort_order ASC LIMIT $limit',
        variables: [Variable.withString(bookSlug)],
        readsFrom: {wordEntries, wordBookAssignments},
      ).get();
      return rows.map((r) => r.read<String>('word_text')).toList();
    }
    final ph = excludeWordIds.map((_) => '?').join(', ');
    final rows = await customSelect(
      'SELECT we.word_text FROM word_entries we '
      'JOIN word_book_assignments wba ON we.word_id = wba.word_id '
      'WHERE wba.book_slug = ? AND we.word_id NOT IN ($ph) '
      'ORDER BY wba.sort_order ASC LIMIT $limit',
      variables: [
        Variable.withString(bookSlug),
        ...excludeWordIds.map(Variable.withString),
      ],
      readsFrom: {wordEntries, wordBookAssignments},
    ).get();
    return rows.map((r) => r.read<String>('word_text')).toList();
  }

  /// Batch-resolve word_id → word_text for a list of word IDs.
  ///
  /// Checks [word_entries] first (ZK / GK), then [cached_words] (CET-4)
  /// for any remaining IDs. Used by review page to build prefetch list
  /// from the FSRS due-card queue (which only stores word_id).
  Future<Map<String, String>> getWordTextsForIds(List<String> wordIds) async {
    if (wordIds.isEmpty) return {};
    final result = <String, String>{};
    // word_entries (ZK / GK)
    final wePh = wordIds.map((_) => '?').join(', ');
    final weRows = await customSelect(
      'SELECT word_id, word_text FROM word_entries WHERE word_id IN ($wePh)',
      variables: wordIds.map(Variable.withString).toList(),
      readsFrom: {wordEntries},
    ).get();
    for (final r in weRows) {
      result[r.read<String>('word_id')] = r.read<String>('word_text');
    }
    // cached_words (CET-4) — only for IDs not yet resolved
    final remaining = wordIds.where((id) => !result.containsKey(id)).toList();
    if (remaining.isNotEmpty) {
      final cwPh = remaining.map((_) => '?').join(', ');
      final cwRows = await customSelect(
        'SELECT word_id, word_text FROM cached_words WHERE word_id IN ($cwPh)',
        variables: remaining.map(Variable.withString).toList(),
        readsFrom: {cachedWords},
      ).get();
      for (final r in cwRows) {
        result[r.read<String>('word_id')] = r.read<String>('word_text');
      }
    }
    return result;
  }

  /// Batch-resolve word_id → translation for a list of word IDs.
  ///
  /// Same lookup order as [getWordTextsForIds]: word_entries first, then
  /// cached_words for remaining. Used by stats page to compute POS radar.
  /// Words with NULL translation are still in the result map with null value.
  Future<Map<String, String?>> getTranslationsForIds(List<String> wordIds) async {
    if (wordIds.isEmpty) return {};
    final result = <String, String?>{};
    final wePh = wordIds.map((_) => '?').join(', ');
    final weRows = await customSelect(
      'SELECT word_id, translation FROM word_entries WHERE word_id IN ($wePh)',
      variables: wordIds.map(Variable.withString).toList(),
      readsFrom: {wordEntries},
    ).get();
    for (final r in weRows) {
      result[r.read<String>('word_id')] = r.readNullable<String>('translation');
    }
    final remaining = wordIds.where((id) => !result.containsKey(id)).toList();
    if (remaining.isNotEmpty) {
      final cwPh = remaining.map((_) => '?').join(', ');
      final cwRows = await customSelect(
        'SELECT word_id, translation FROM cached_words WHERE word_id IN ($cwPh)',
        variables: remaining.map(Variable.withString).toList(),
        readsFrom: {cachedWords},
      ).get();
      for (final r in cwRows) {
        result[r.read<String>('word_id')] = r.readNullable<String>('translation');
      }
    }
    return result;
  }

  /// Open the database connection.
  /// Uses the same file name as the old sqflite database for seamless upgrade.
  static QueryExecutor _openConnection() {
    return SqfliteQueryExecutor.inDatabaseFolder(
      path: 'meow_progress.db',
    );
  }
}
