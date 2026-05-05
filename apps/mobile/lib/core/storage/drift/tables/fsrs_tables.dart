/// FSRS-related drift table definitions.
///
/// Three new tables for the FSRS memory model integration:
///   - card_states: per-word FSRS card scheduling state
///   - review_logs: immutable review history (INSERT-ONLY, never update/delete)
///   - cached_words: local word pool cache for offline study
import 'package:drift/drift.dart';

// ==================== card_states ====================
/// Each word's FSRS card state. One row per word.
/// Fields mirror the fsrs library's Card class for round-trip serialization.
@TableIndex(name: 'idx_card_states_due', columns: {#due})
@TableIndex(name: 'idx_card_states_state', columns: {#state})
class CardStates extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Word identifier, e.g. 'cet4-abandon'. UNIQUE — one card per word.
  TextColumn get wordId => text().named('word_id').unique()();

  /// FSRS stability parameter. Nullable for brand-new cards.
  RealColumn get stability => real().nullable()();

  /// FSRS difficulty parameter. Nullable for brand-new cards.
  RealColumn get difficulty => real().nullable()();

  /// Next due date as UTC epoch milliseconds.
  IntColumn get due => integer()();

  /// Last review date as UTC epoch ms. Null if never reviewed.
  IntColumn get lastReview => integer().named('last_review').nullable()();

  /// Card state: 1=Learning, 2=Review, 3=Relearning
  /// (fsrs library has no State.new; new cards start as State.learning=1)
  IntColumn get state => integer().withDefault(const Constant(1))();

  /// Learning/relearning step index. Null when in Review state.
  IntColumn get step => integer().nullable()();

  /// Number of consecutive successful reviews.
  IntColumn get reps => integer().withDefault(const Constant(0))();

  /// Number of times the card was forgotten (lapsed).
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  /// When this card_state row was created. UTC epoch ms.
  /// Used by countNewCardsToday() to track daily new card introductions.
  IntColumn get createdAt => integer().named('created_at')();
}

// ==================== review_logs ====================
/// Immutable review history. INSERT-ONLY — never update or delete.
/// This is the raw data source for fsrs-optimizer.
@TableIndex(name: 'idx_review_logs_word_id', columns: {#wordId})
@TableIndex(name: 'idx_review_logs_review_time', columns: {#reviewTimeUtc})
class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// FK to card_states.id
  IntColumn get cardStateId =>
      integer().named('card_state_id').references(CardStates, #id)();

  /// Redundant word_id for convenient querying without JOIN.
  TextColumn get wordId => text().named('word_id')();

  /// Rating: 1=Again, 2=Hard, 3=Good, 4=Easy
  IntColumn get rating => integer()();

  /// When this review happened. UTC epoch ms.
  IntColumn get reviewTimeUtc => integer().named('review_time_utc')();

  /// Days elapsed since last review.
  RealColumn get elapsedDays => real().named('elapsed_days')();

  /// Days that FSRS had scheduled before this review.
  RealColumn get scheduledDays => real().named('scheduled_days')();

  /// Card state before this review (1/2/3).
  IntColumn get stateBefore => integer().named('state_before')();

  /// Card stability before this review.
  RealColumn get stabilityBefore =>
      real().named('stability_before').nullable()();

  /// Card difficulty before this review.
  RealColumn get difficultyBefore =>
      real().named('difficulty_before').nullable()();

  /// App version string for traceability.
  TextColumn get clientVersion =>
      text().named('client_version').nullable()();
}

// ==================== preset_wordbooks ====================
/// Catalog of built-in preset wordbooks (中考, 高考, etc.).
/// One row per supported book slug; populated by WordbookLoader on first launch.
class PresetWordbooks extends Table {
  /// Stable identifier, e.g. 'zk', 'gk'.
  TextColumn get slug => text()();

  /// Human-readable name, e.g. '中考', '高考'.
  TextColumn get displayName => text().named('display_name')();

  /// Total number of words in this book.
  IntColumn get totalWords =>
      integer().named('total_words').withDefault(const Constant(0))();

  /// Optional description of the book.
  TextColumn get description => text().nullable()();

  /// Display ordering (smaller = shown first).
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();

  /// Content version from the bundled asset JSON (e.g. '2').
  /// WordbookLoader re-imports when this differs from the JSON's contentVersion.
  TextColumn get contentVersion =>
      text().named('content_version').nullable()();

  @override
  Set<Column> get primaryKey => {slug};
}

// ==================== word_entries ====================
/// Normalised word master table.
/// One row per unique word (canonical across all books).
/// Word ID = lowercase word text, e.g. 'ability'.
class WordEntries extends Table {
  /// Canonical word identifier: lowercase word text, e.g. 'ability'.
  TextColumn get wordId => text().named('word_id')();

  /// Display form of the word, e.g. 'ability'.
  TextColumn get wordText => text().named('word_text')();

  /// IPA or simplified phonetic notation. Nullable.
  TextColumn get phonetic => text().nullable()();

  /// Short Chinese meaning (one phrase), e.g. '能力'.
  TextColumn get meaning => text()();

  /// Full multi-POS Chinese translation (newline-separated). Nullable.
  TextColumn get translation => text().nullable()();

  /// English definition from CSV. Nullable.
  TextColumn get definition => text().nullable()();

  /// BNC frequency rank (lower = more common). Default 0 = unknown.
  IntColumn get frequencyRank =>
      integer().named('frequency_rank').withDefault(const Constant(0))();

  /// Exchange / word-forms field from CSV (e.g. 's:abilities'). Nullable.
  TextColumn get wordForms => text().named('word_forms').nullable()();

  /// When this word was imported from the bundled asset. UTC epoch ms.
  /// Named imported_at (not cached_at) to distinguish from cloud-cache semantics.
  IntColumn get importedAt => integer().named('imported_at')();

  @override
  Set<Column> get primaryKey => {wordId};
}

// ==================== word_book_assignments ====================
/// Many-to-many join table: a word can belong to multiple books.
/// E.g. "ability" belongs to both 'zk' and 'gk'.
@TableIndex(name: 'idx_wba_book_order', columns: {#bookSlug, #sortOrder})
class WordBookAssignments extends Table {
  /// FK → word_entries.word_id (canonical, book-insensitive).
  TextColumn get wordId => text().named('word_id')();

  /// FK → preset_wordbooks.slug, e.g. 'zk'.
  TextColumn get bookSlug => text().named('book_slug')();

  /// Position of this word within the book (CSV row order, 1-based).
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();

  /// Traceable source key from the original CSV, e.g. 'zk-3'.
  /// Allows tracing word_id back to its original CSV row independent of
  /// the canonical key. Nullable for backwards compat with older assets.
  TextColumn get sourceKey => text().named('source_key').nullable()();

  @override
  Set<Column> get primaryKey => {wordId, bookSlug};
}

// ==================== example_sentences ====================
/// Per-word AI-generated example sentences (1 word → up to 5 examples).
/// Inserted once by WordbookLoader; INSERT OR IGNORE for shared words.
/// The UNIQUE index on (word_id, sort_order) makes INSERT OR IGNORE truly
/// idempotent: a duplicate example is silently discarded instead of appended.
///
/// v9 (P0): added `stable_id` content-addressable ID column. App uses this
/// to query `/api/v1/examples/:stable_id/audio` per DB v0.3.0 §3.4.
/// Nullable ONLY for transitional rows imported before v9; new imports MUST
/// populate it (assets/words/*.json schemaVersion 4 + contentVersion 3 carries it).
@TableIndex(name: 'idx_es_word_order', columns: {#wordId, #sortOrder}, unique: true)
@TableIndex(name: 'idx_es_stable_id', columns: {#stableId}, unique: true)
class ExampleSentences extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// FK → word_entries.word_id.
  TextColumn get wordId => text().named('word_id')();

  /// v0.3.0 P0: content-addressable stable ID.
  /// = sha256_24(canonical_json([normalize_word(word_text), normalize_text(en)]))
  /// Nullable for legacy rows imported before v9 migration; populated by all
  /// new WordbookLoader imports.
  TextColumn get stableId => text().named('stable_id').nullable()();

  /// Sense/义项 label, e.g. 'v. 放弃；抛弃'.
  TextColumn get sense => text()();

  /// English example sentence (may contain [bracket] highlight markers).
  TextColumn get en => text()();

  /// Chinese translation (may contain [bracket] highlight markers).
  TextColumn get cn => text()();

  /// Display order within the word (0 = first example shown).
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
}

// ==================== cached_words ====================
// REMOVED in v0.3.0 P1 (drift schema v10).
//
// CET-4 used to flow through this dedicated table (`book_id='book-001'`,
// PK = `cet4-abandon` form). After P1 the canonical word path
// (`word_entries` + `word_book_assignments` populated by WordbookLoader)
// covers all books. The migration drops the table and strips the `cet4-`
// prefix from `word_records.word_id` and `card_states.word_id` so user
// history continues to resolve.
//
// Anywhere that previously read `cached_words` should be repointed to
// `word_entries`, joining `word_book_assignments` for book-scoped queries.

// ==================== audio_file_cache (v0.3.0 P2.1) ====================
/// Tracks downloaded audio binaries cached on the device's filesystem.
///
/// Per DB v0.3.0 §7.4. The audio binary itself lives at `local_path`
/// (typically `{appDocs}/audio/example_{audio_id}.mp3`); this table stores
/// the metadata used by the cache eviction strategy (§7.4.1):
///
///   - **Trigger 1 (capacity + LRU)**: ORDER BY last_played_at ASC and
///     evict until total bytes ≤ cap × 0.8.
///   - **Trigger 2 (content / audio version orphan)**: rows where
///     `cached_content_version` no longer matches the active manifest, or
///     `audio_id` no longer appears in the active `audio_assets`, are
///     evicted (file deleted + row deleted).
///
/// All comparisons happen between SQLite columns; the App never recomputes
/// SHA-256 from disk (DB §7.4.1 forbids that).
@TableIndex(
    name: 'idx_audio_file_cache_last_played', columns: {#lastPlayedAt})
@TableIndex(
    name: 'idx_audio_file_cache_content_version',
    columns: {#cachedContentVersion})
class AudioFileCache extends Table {
  /// = audio_assets.id (24-hex sha256, includes audio_version).
  TextColumn get audioId => text().named('audio_id')();

  /// Absolute path to the cached binary on the device filesystem.
  TextColumn get localPath => text().named('local_path')();

  /// Byte size of the cached file. Required for capacity calculation.
  IntColumn get bytes => integer()();

  /// When this row was first written. UTC epoch ms.
  IntColumn get cachedAt => integer().named('cached_at')();

  /// When the audio was last played. UTC epoch ms. Nullable means
  /// "downloaded but never played" — also a valid state.
  IntColumn get lastPlayedAt =>
      integer().named('last_played_at').nullable()();

  /// SHA-256 of the binary as reported by `audio_assets.checksum_sha256`
  /// at download time. Used to detect server-side replacements.
  TextColumn get cachedChecksum =>
      text().named('cached_checksum').nullable()();

  /// content_version of the manifest package the audio was sourced from.
  /// Used by §7.4.1 trigger 2 for orphan detection.
  TextColumn get cachedContentVersion =>
      text().named('cached_content_version').nullable()();

  @override
  Set<Column> get primaryKey => {audioId};
}

