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

// ==================== cached_words ====================
/// Local word pool cache. Downloaded from backend for offline study.
/// Session builder queries this table to find new-word candidates.
class CachedWords extends Table {
  /// Word identifier, e.g. 'cet4-abandon'. Primary key.
  TextColumn get wordId => text().named('word_id')();

  /// Which book this word belongs to, e.g. 'book-001'.
  TextColumn get bookId => text().named('book_id')();

  /// The word text, e.g. 'abandon'.
  TextColumn get wordText => text().named('word_text')();

  /// Short Chinese meaning, e.g. '放弃'.
  TextColumn get meaning => text()();

  /// Phonetic notation, e.g. '/əˈbændən/'.
  TextColumn get phonetic => text().nullable()();

  /// Full Chinese translation (multi-POS).
  TextColumn get translation => text().nullable()();

  /// Frequency rank (lower = more common). Used for sort_order.
  IntColumn get frequencyRank =>
      integer().named('frequency_rank').withDefault(const Constant(0))();

  /// Learning order (typically same as frequency_rank).
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();

  /// When this word was cached locally. UTC epoch ms.
  IntColumn get cachedAt => integer().named('cached_at')();

  @override
  Set<Column> get primaryKey => {wordId};
}
