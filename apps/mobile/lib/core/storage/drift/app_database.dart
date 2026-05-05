import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';

import 'tables/legacy_tables.dart';
import 'tables/fsrs_tables.dart';
import 'tables/session_tables.dart';
import 'tables/enrichment_tables.dart';

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
///   v5–v8:            session, review_records, enrichment, morpheme tables
///   v9 (P0):          example_sentences.stable_id column (content-addressable IDs)
///   v10 (P1):         cached_words DROPPED — CET-4 unified into word_entries;
///                       word_records.word_id and card_states.word_id strip
///                       'cet4-' prefix in place to preserve user history.
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
  // (CachedWords removed in v10; CET-4 now flows through word_entries.)
  // Content layer (v3, wordbooks + examples)
  PresetWordbooks,
  WordEntries,
  WordBookAssignments,
  ExampleSentences,
  // Session layer (v5, Need #8: local Session truth + linked review attempts)
  Sessions,
  ReviewRecords,
  // Enrichment layer (v7, Need #11: other forms / synonyms+antonyms / common phrases)
  WordForms,
  WordRelations,
  WordPhrases,
  // Morpheme layer (v8, Need #12: word root / affix catalog + per-word matches)
  MorphemeEntries,
  WordMorphemeMatches,
  // Audio cache (v11, P2.1: device-local mp3 cache index, DB v0.3.0 §7.4)
  AudioFileCache,
])
class AppDatabase extends _$AppDatabase {
  /// Production constructor — process-wide singleton.
  ///
  /// drift recommends one [GeneratedDatabase] per process (see drift docs:
  /// "creating multiple instances when these two databases use the same
  /// QueryExecutor causes race conditions"). The factory routes every
  /// `AppDatabase()` call back to a single lazily-built `_instance`, so
  /// services that previously did `AppDatabase()` inside their own ctor
  /// (e.g. [AudioCacheRepository], [ExampleAudioService], [WordAudioService])
  /// now share the main one without any call-site change.
  ///
  /// This was the trigger for the "multiple databases" warning observed
  /// during P2.1 study-page boot, and the implicit race window during
  /// migrations on cold start. With the factory, only `_internal()` ever
  /// hits drift's `super(_openConnection())` — exactly once per process.
  factory AppDatabase() => _instance ??= AppDatabase._internal();
  AppDatabase._internal() : super(_openConnection());
  static AppDatabase? _instance;

  /// Testing path — bypasses the singleton and lets each test inject its
  /// own [QueryExecutor] (typically `NativeDatabase.memory()`). Tests must
  /// NEVER call `AppDatabase()` directly; the production singleton would
  /// leak across tests and cause cross-test pollution.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 11;

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
            // Only create the 2 new FSRS tables + their indexes.
            //
            // Historical note: v2 also created a `cached_words` table, but
            // v10 (P1) drops it. A v1→v10 fresh upgrade therefore skips
            // creating it, since the v10 step below would just drop it
            // anyway.
            await m.createTable(cardStates);
            await m.createTable(reviewLogs);
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
          // Defensive migration: dev devices accumulate intermediate states
          // (e.g. column added by an earlier build but PRAGMA user_version
          // didn't advance), so every step is idempotent — already-present
          // columns / tables are skipped silently. Anything else still throws.
          if (from < 5) {
            // v5 (Need #8): local session truth + review attempt local table +
            // word_records.session_id linkage.
            await _safeCreateTable(m, sessions);
            await _safeCreateTable(m, reviewRecords);
            await _safeAddColumn(m, wordRecords, wordRecords.sessionId);
          }
          if (from >= 5 && from < 6) {
            // v6 (Need #10): record FSRS rating per review attempt for the
            // local review log. Only run when upgrading FROM exactly v5 —
            // a v1→v6 upgrade above already created review_records with the
            // current definition (rating included), so we must NOT add it
            // again here or sqlite throws "duplicate column".
            await _safeAddColumn(m, reviewRecords, reviewRecords.rating);
          }
          if (from < 7) {
            // v7 (Need #11): local-only word enrichment layer.
            // Three tables, no foreign keys (joined by lowercase word_text
            // at read time). Indexes are emitted by drift's @TableIndex.
            await _safeCreateTable(m, wordForms);
            await _safeCreateTable(m, wordRelations);
            await _safeCreateTable(m, wordPhrases);
          }
          if (from < 8) {
            // v8 (Need #12): word root / affix catalog + per-word matches.
            // Same idempotent guard so partially-applied dev devices
            // don't crash on re-run.
            await _safeCreateTable(m, morphemeEntries);
            await _safeCreateTable(m, wordMorphemeMatches);
          }
          if (from < 9) {
            // v9 (P0): example_sentences gains stable_id column for v0.3.0
            // content-addressable IDs. Nullable so existing rows imported
            // before this migration don't violate NOT NULL; new
            // WordbookLoader imports populate it from assets/words/*.json
            // (schemaVersion 4 + contentVersion 3+).
            //
            // Asset-derived data — safe to flush and reload to ensure full
            // population. WordbookLoader will detect contentVersion mismatch
            // and re-import on next launch.
            await _safeAddColumn(m, exampleSentences, exampleSentences.stableId);
            // Guard the partial index so migration tests that don't pre-create
            // example_sentences don't crash here either.
            final hasTable = await customSelect(
                "SELECT 1 FROM sqlite_master WHERE type='table' "
                "AND name='example_sentences'").get();
            if (hasTable.isNotEmpty) {
              await customStatement(
                  'CREATE UNIQUE INDEX IF NOT EXISTS idx_es_stable_id '
                  'ON example_sentences(stable_id) WHERE stable_id IS NOT NULL');
            }
          }
          if (from < 10) {
            // v10 (P1): unify word storage. CET-4's `cet4-abandon` form is
            // collapsed to canonical `abandon`, matching ZK / GK. The legacy
            // `cached_words` table goes away — CET-4 now flows through
            // `word_entries` + `word_book_assignments` like the others.
            //
            // User history (`word_records`, `card_states`) is preserved by
            // stripping the `cet4-` prefix in place. card_states has a
            // UNIQUE(word_id) constraint, so we first delete any prefixed
            // row whose canonical sibling already exists (rare overlap when
            // user has studied the word in BOTH CET-4 and ZK pre-P1).
            //
            // Each table operation is guarded by `_tableExists(...)` so
            // partial-state dev devices and migration tests that simulate
            // older schemas (without all intermediate tables) don't crash.
            if (await _tableExists('card_states')) {
              await customStatement(
                  "DELETE FROM card_states "
                  "WHERE word_id LIKE 'cet4-%' "
                  "AND SUBSTR(word_id, 6) IN (SELECT word_id FROM card_states "
                  "                           WHERE word_id NOT LIKE 'cet4-%')");
              await customStatement(
                  "UPDATE card_states "
                  "SET word_id = SUBSTR(word_id, 6) "
                  "WHERE word_id LIKE 'cet4-%'");
            }
            if (await _tableExists('word_records')) {
              await customStatement(
                  "UPDATE word_records "
                  "SET word_id = SUBSTR(word_id, 6) "
                  "WHERE word_id LIKE 'cet4-%'");
            }
            // Drop legacy CET-4-only table; data flows through word_entries
            // populated by WordbookLoader from assets/words/book-001.json.
            await customStatement('DROP TABLE IF EXISTS cached_words');
            // The above migration runs alongside `contentVersion '3'`
            // detection in WordbookLoader, which triggers a flush+reimport
            // of the content-layer tables on next launch — the new
            // book-001.json (canonical wordIds + schemaVersion 4) will
            // populate word_entries / word_book_assignments / example_sentences
            // for CET-4.
          }
          if (from < 11) {
            // v11 (P2.1): device-local audio cache index. Tracks the mp3
            // files sitting in the app's docs dir; drives the LRU +
            // content-version eviction strategies in DB v0.3.0 §7.4.1.
            // Idempotent (safe-create) so partial-state dev devices can
            // re-run.
            await _safeCreateTable(m, audioFileCache);
          }
        },
      );

  /// Add a column iff it doesn't already exist on [table]. Reads the live
  /// `PRAGMA table_info(...)` rather than relying on drift's internal
  /// schema cache so it survives "schema drifted from user_version" cases.
  Future<void> _safeAddColumn(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    final cols = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    if (cols.isEmpty) {
      // Table doesn't exist — nothing to alter. This guards partial-state
      // dev devices and migration tests that simulate older schemas
      // without all intermediate tables. The table will be created
      // through its normal onUpgrade branch (or the next createAll for a
      // truly fresh install).
      return;
    }
    final existing =
        cols.map((r) => r.read<String>('name')).toSet();
    if (existing.contains(column.$name)) return;
    await m.addColumn(table, column);
  }

  /// Returns true iff a table with the given name exists in the database.
  /// Reads sqlite_master directly so it works regardless of drift's internal
  /// schema cache state.
  Future<bool> _tableExists(String tableName) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      variables: [Variable.withString(tableName)],
    ).get();
    return rows.isNotEmpty;
  }

  /// Create a table iff it doesn't already exist. Uses sqlite_master so it
  /// survives the same dev-build skew as [_safeAddColumn]. Drift's
  /// `m.createTable` does not emit `IF NOT EXISTS`, so we have to gate it
  /// ourselves.
  Future<void> _safeCreateTable(Migrator m, TableInfo table) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      variables: [Variable.withString(table.actualTableName)],
    ).get();
    if (rows.isNotEmpty) return;
    await m.createTable(table);
  }

  /// Return the next word in [bookSlug] that the user has not yet studied.
  ///
  /// v0.3.0 P1: unified path for ALL books (CET-4 / ZK / GK). The legacy
  /// `getNextUnstudiedWord(bookId)` that read `cached_words` is gone —
  /// every caller should use [getNextWordFromWordbook] now.
  ///
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
  /// v0.3.0 P1: 'book-001' (CET-4) is now in preset_wordbooks like ZK / GK
  /// (populated by WordbookLoader from assets/words/book-001.json).
  Future<List<PresetWordbook>> getAllPresetWordbooks() {
    return (select(presetWordbooks)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])
    ).get();
  }

  /// Return all word IDs belonging to [bookSlug].
  ///
  /// v0.3.0 P1: unified path through `word_book_assignments` for all books
  /// including CET-4. The legacy `cached_words` branch is gone.
  ///
  /// Used by the home page to intersect with mastered IDs (from the sqflite
  /// [word_records] table) to compute per-book mastered word count.
  Future<Set<String>> getWordIdsForBook(String bookSlug) async {
    final rows = await customSelect(
      'SELECT word_id FROM word_book_assignments WHERE book_slug = ?',
      variables: [Variable.withString(bookSlug)],
      readsFrom: {wordBookAssignments},
    ).get();
    return rows.map((r) => r.read<String>('word_id')).toSet();
  }

  /// Count total words available in [bookSlug].
  ///
  /// v0.3.0 P1: unified path — all books (CET-4 / ZK / GK) live in
  /// `word_book_assignments`.
  Future<int> countWordsInBook(String bookSlug) async {
    final r = await customSelect(
      'SELECT COUNT(*) AS cnt FROM word_book_assignments WHERE book_slug = ?',
      variables: [Variable.withString(bookSlug)],
      readsFrom: {wordBookAssignments},
    ).getSingle();
    return r.read<int>('cnt');
  }

  /// Look up a single [WordEntry] by canonical [wordId].
  /// Returns null if not found.
  ///
  /// v0.3.0 P1: getCachedWordById is gone — all words flow through word_entries.
  Future<WordEntry?> getWordEntryById(String wordId) {
    return (select(wordEntries)..where((t) => t.wordId.equals(wordId)))
        .getSingleOrNull();
  }

  /// Return up to [limit] example sentences for [wordId] from [example_sentences],
  /// ordered by sort_order ASC.
  ///
  /// v0.3.0 P1: with canonical word_ids, ZK 'ability' and CET-4 'ability'
  /// share the same `word_id='ability'` and therefore the same example pool.
  /// [getExamplesForWordText] is functionally equivalent now (the join
  /// becomes a no-op) but is still provided for callers that only have the
  /// raw text and not the normalized id.
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
              // v0.3.0 P0: must hydrate stable_id so UI can show example
              // play button. Drift's auto-mapped queries pull every column,
              // but customSelect needs explicit reads — easy to miss when
              // a column is added later (this was the cause of "exemple
              // shows but no audio button" pre-fix).
              stableId: r.readNullable<String>('stable_id'),
            ))
        .toList();
  }

  /// Return up to [limit] example sentences for any word whose lowercased
  /// `word_text` matches [wordText]. Joins through `word_entries` so the
  /// same English word in different books (CET-4 / ZK / GK) shares one
  /// example pool — same approach Need #11 used for forms / relations /
  /// phrases. `LOWER(?)` keeps the comparison case-insensitive.
  Future<List<ExampleSentence>> getExamplesForWordText(
    String wordText, {
    int limit = 3,
  }) async {
    final key = wordText.trim().toLowerCase();
    if (key.isEmpty) return const [];
    final rows = await customSelect(
      'SELECT es.* FROM example_sentences es '
      'JOIN word_entries we ON we.word_id = es.word_id '
      'WHERE LOWER(we.word_text) = ? '
      'ORDER BY es.sort_order ASC LIMIT $limit',
      variables: [Variable.withString(key)],
      readsFrom: {exampleSentences, wordEntries},
    ).get();
    return rows
        .map((r) => ExampleSentence(
              id: r.read<int>('id'),
              wordId: r.read<String>('word_id'),
              sense: r.read<String>('sense'),
              en: r.read<String>('en'),
              cn: r.read<String>('cn'),
              sortOrder: r.read<int>('sort_order'),
              // v0.3.0 P0: see getExamplesForWord — same stable_id hydration.
              stableId: r.readNullable<String>('stable_id'),
            ))
        .toList();
  }

  /// Peek at the next [limit] unstudied word_text values in [bookSlug].
  ///
  /// v0.3.0 P1: unified path — same query for all books (CET-4 / ZK / GK).
  Future<List<String>> peekNextWordTexts(
    String bookSlug,
    Set<String> excludeWordIds,
    int limit,
  ) async {
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
  /// v0.3.0 P1: single source — word_entries holds all books.
  /// Used by review page to build prefetch list from the FSRS due-card queue
  /// (which only stores word_id).
  Future<Map<String, String>> getWordTextsForIds(List<String> wordIds) async {
    if (wordIds.isEmpty) return {};
    final result = <String, String>{};
    final wePh = wordIds.map((_) => '?').join(', ');
    final weRows = await customSelect(
      'SELECT word_id, word_text FROM word_entries WHERE word_id IN ($wePh)',
      variables: wordIds.map(Variable.withString).toList(),
      readsFrom: {wordEntries},
    ).get();
    for (final r in weRows) {
      result[r.read<String>('word_id')] = r.read<String>('word_text');
    }
    return result;
  }

  /// Batch-resolve word_id → translation for a list of word IDs.
  ///
  /// v0.3.0 P1: single source — word_entries holds all books.
  /// Used by stats page to compute POS radar. Words with NULL translation
  /// are still in the result map with null value.
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
