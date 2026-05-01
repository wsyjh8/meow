/// Legacy table definitions for drift.
///
/// These 5 tables existed in raw sqflite (schema v1).
/// The drift definitions MUST produce identical SQL to the original
/// _createTables() in local_database.dart.
///
/// Original SQL reference:
///   word_records: id INTEGER PK AUTO, word_id TEXT, book_id TEXT,
///                 study_type TEXT DEFAULT 'new', action_result TEXT,
///                 created_at TEXT, synced INTEGER DEFAULT 0
///   wordbook_progress: id INTEGER PK AUTO, book_id TEXT UNIQUE,
///                      total_words INTEGER DEFAULT 0, completed_words INTEGER DEFAULT 0,
///                      updated_at TEXT
///   daily_checkins: id INTEGER PK AUTO, date TEXT UNIQUE,
///                   checked_in INTEGER DEFAULT 1, created_at TEXT
///   custom_wordbooks: id INTEGER PK AUTO, name TEXT, word_count INTEGER DEFAULT 0,
///                     created_at TEXT
///   vocabulary_notebook: id INTEGER PK AUTO, word TEXT, meaning TEXT nullable,
///                        note TEXT nullable, created_at TEXT
import 'package:drift/drift.dart';

// ==================== word_records ====================
class WordRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
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
class WordbookProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bookId => text().named('book_id').unique()();
  IntColumn get totalWords =>
      integer().named('total_words').withDefault(const Constant(0))();
  IntColumn get completedWords =>
      integer().named('completed_words').withDefault(const Constant(0))();
  TextColumn get updatedAt => text().named('updated_at')();
}

// ==================== daily_checkins ====================
class DailyCheckins extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text().unique()();
  IntColumn get checkedIn =>
      integer().named('checked_in').withDefault(const Constant(1))();
  TextColumn get createdAt => text().named('created_at')();
}

// ==================== custom_wordbooks ====================
class CustomWordbooks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get wordCount =>
      integer().named('word_count').withDefault(const Constant(0))();
  TextColumn get createdAt => text().named('created_at')();
}

// ==================== vocabulary_notebook ====================
class VocabularyNotebook extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text()();
  TextColumn get meaning => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text().named('created_at')();
}
