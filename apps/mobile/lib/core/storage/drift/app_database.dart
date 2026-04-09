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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing: accept any QueryExecutor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // Fresh install: drift creates all 8 tables from definitions.
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
        },
      );

  /// Open the database connection.
  /// Uses the same file name as the old sqflite database for seamless upgrade.
  static QueryExecutor _openConnection() {
    return SqfliteQueryExecutor.inDatabaseFolder(
      path: 'meow_progress.db',
    );
  }
}
