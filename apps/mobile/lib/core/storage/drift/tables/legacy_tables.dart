/// Legacy table definitions for drift.
///
/// These 5 tables existed in raw sqflite (schema v1). drift took over
/// schema ownership in v2 onUpgrade but `LocalDatabase._createTables`
/// kept building them in parallel until v13 / PR-C-α (need 23 Phase C),
/// at which point drift became the SOLE schema owner (plan-023-C-v2
/// D1 + §4.0). The drift table classes here are therefore the truth
/// for both fresh-install and upgrade paths.
///
/// v13 (need 23 Phase C, plan-023-C-v2 §4.2): adds `user_id` to all 5
/// tables for per-user partition. UNIQUE constraints on
/// `wordbook_progress.book_id` and `daily_checkins.date` are widened
/// to composite `(user_id, …)` so two users can hold the same book /
/// date without collision.
///
/// Reference SQL (v13 onCreate output):
///   word_records: id INTEGER PK AUTO, user_id TEXT NOT NULL,
///                 word_id TEXT, book_id TEXT,
///                 study_type TEXT DEFAULT 'new', action_result TEXT,
///                 created_at TEXT, synced INTEGER DEFAULT 0,
///                 session_id TEXT NULL
///   wordbook_progress: id INTEGER PK AUTO, user_id TEXT NOT NULL,
///                      book_id TEXT NOT NULL,
///                      total_words / completed_words INTEGER DEFAULT 0,
///                      updated_at TEXT,
///                      UNIQUE(user_id, book_id)
///   daily_checkins: id INTEGER PK AUTO, user_id TEXT NOT NULL,
///                   date TEXT NOT NULL,
///                   checked_in INTEGER DEFAULT 1, created_at TEXT,
///                   UNIQUE(user_id, date)
///   custom_wordbooks: id INTEGER PK AUTO, user_id TEXT NOT NULL,
///                     name TEXT, word_count INTEGER DEFAULT 0,
///                     created_at TEXT
///   vocabulary_notebook: id INTEGER PK AUTO, user_id TEXT NOT NULL,
///                        word TEXT, meaning TEXT nullable, note TEXT
///                        nullable, created_at TEXT
library;

import 'package:drift/drift.dart';

// ==================== word_records ====================
@TableIndex(name: 'idx_word_records_user', columns: {#userId})
class WordRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get wordId => text().named('word_id')();
  TextColumn get bookId => text().named('book_id')();
  TextColumn get studyType =>
      text().named('study_type').withDefault(const Constant('new'))();
  TextColumn get actionResult => text().named('action_result')();
  TextColumn get createdAt => text().named('created_at')();
  IntColumn get synced => integer().withDefault(const Constant(0))();
  TextColumn get sessionId => text().named('session_id').nullable()();
}

// ==================== wordbook_progress ====================
// v13 (PR-C-α): UNIQUE(book_id) → UNIQUE(user_id, book_id) so two users
// can hold the same preset book without colliding.
@TableIndex(
  name: 'idx_wordbook_progress_user_book',
  columns: {#userId, #bookId},
  unique: true,
)
class WordbookProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get bookId => text().named('book_id')();
  IntColumn get totalWords =>
      integer().named('total_words').withDefault(const Constant(0))();
  IntColumn get completedWords =>
      integer().named('completed_words').withDefault(const Constant(0))();
  TextColumn get updatedAt => text().named('updated_at')();
}

// ==================== daily_checkins ====================
// v13 (PR-C-α): UNIQUE(date) → UNIQUE(user_id, date).
@TableIndex(
  name: 'idx_daily_checkins_user_date',
  columns: {#userId, #date},
  unique: true,
)
class DailyCheckins extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get date => text()();
  IntColumn get checkedIn =>
      integer().named('checked_in').withDefault(const Constant(1))();
  TextColumn get createdAt => text().named('created_at')();
}

// ==================== custom_wordbooks ====================
@TableIndex(name: 'idx_custom_wordbooks_user', columns: {#userId})
class CustomWordbooks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get name => text()();
  IntColumn get wordCount =>
      integer().named('word_count').withDefault(const Constant(0))();
  TextColumn get createdAt => text().named('created_at')();
}

// ==================== vocabulary_notebook ====================
@TableIndex(name: 'idx_vocabulary_notebook_user', columns: {#userId})
class VocabularyNotebook extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get word => text()();
  TextColumn get meaning => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text().named('created_at')();
}
