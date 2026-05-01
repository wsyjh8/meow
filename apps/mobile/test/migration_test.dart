import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/storage/drift/app_database.dart';

void main() {
  group('drift migration', () {
    test('fresh install (onCreate): all 8 tables exist', () async {
      // Fresh database — drift runs onCreate which creates all tables
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      // Verify all 8 tables exist by querying each
      // Legacy tables
      expect(await db.select(db.wordRecords).get(), isEmpty);
      expect(await db.select(db.wordbookProgress).get(), isEmpty);
      expect(await db.select(db.dailyCheckins).get(), isEmpty);
      expect(await db.select(db.customWordbooks).get(), isEmpty);
      expect(await db.select(db.vocabularyNotebook).get(), isEmpty);

      // FSRS tables
      expect(await db.select(db.cardStates).get(), isEmpty);
      expect(await db.select(db.reviewLogs).get(), isEmpty);
      expect(await db.select(db.cachedWords).get(), isEmpty);

      await db.close();
    });

    test('fresh install: can insert and read from all FSRS tables', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

      // card_states
      await db.into(db.cardStates).insert(CardStatesCompanion.insert(
            wordId: 'test-word-1',
            due: nowMs,
            createdAt: nowMs,
          ));
      final cards = await db.select(db.cardStates).get();
      expect(cards.length, 1);
      expect(cards.first.wordId, 'test-word-1');
      expect(cards.first.state, 1); // default Learning

      // review_logs
      await db.into(db.reviewLogs).insert(ReviewLogsCompanion.insert(
            cardStateId: cards.first.id,
            wordId: 'test-word-1',
            rating: 3,
            reviewTimeUtc: nowMs,
            elapsedDays: 0.0,
            scheduledDays: 0.0,
            stateBefore: 1,
          ));
      final logs = await db.select(db.reviewLogs).get();
      expect(logs.length, 1);
      expect(logs.first.rating, 3);

      // cached_words
      await db.into(db.cachedWords).insert(CachedWordsCompanion.insert(
            wordId: 'cet4-hello',
            bookId: 'book-001',
            wordText: 'hello',
            meaning: '你好',
            cachedAt: nowMs,
          ));
      final cached = await db.select(db.cachedWords).get();
      expect(cached.length, 1);
      expect(cached.first.wordText, 'hello');

      await db.close();
    });

    test('upgrade from v1: simulates existing sqflite database', () async {
      // Simulate a v1 database by creating it with raw SQL first,
      // then opening with drift (which will run onUpgrade v1→v2).
      final nativeDb = NativeDatabase.memory(
        setup: (rawDb) {
          // Simulate sqflite v1 schema — create the 5 legacy tables
          rawDb.execute('PRAGMA user_version = 1');
          rawDb.execute('''
            CREATE TABLE word_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              word_id TEXT NOT NULL,
              book_id TEXT NOT NULL,
              study_type TEXT NOT NULL DEFAULT 'new',
              action_result TEXT NOT NULL,
              created_at TEXT NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0
            )
          ''');
          rawDb.execute('''
            CREATE TABLE wordbook_progress (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              book_id TEXT NOT NULL UNIQUE,
              total_words INTEGER NOT NULL DEFAULT 0,
              completed_words INTEGER NOT NULL DEFAULT 0,
              updated_at TEXT NOT NULL
            )
          ''');
          rawDb.execute('''
            CREATE TABLE daily_checkins (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL UNIQUE,
              checked_in INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL
            )
          ''');
          rawDb.execute('''
            CREATE TABLE custom_wordbooks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              word_count INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
          rawDb.execute('''
            CREATE TABLE vocabulary_notebook (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              word TEXT NOT NULL,
              meaning TEXT,
              note TEXT,
              created_at TEXT NOT NULL
            )
          ''');
          // Insert some v1 data
          rawDb.execute(
              "INSERT INTO word_records (word_id, book_id, action_result, created_at) "
              "VALUES ('cet4-old', 'book-001', 'know', '2026-04-07T12:00:00Z')");
        },
      );

      final db = AppDatabase.forTesting(nativeDb);

      // Verify legacy data survived migration
      final records = await db.select(db.wordRecords).get();
      expect(records.length, 1);
      expect(records.first.wordId, 'cet4-old');
      expect(records.first.actionResult, 'know');

      // Verify new FSRS tables were created
      expect(await db.select(db.cardStates).get(), isEmpty);
      expect(await db.select(db.reviewLogs).get(), isEmpty);
      expect(await db.select(db.cachedWords).get(), isEmpty);

      // Verify we can write to new tables
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.into(db.cardStates).insert(CardStatesCompanion.insert(
            wordId: 'cet4-new',
            due: nowMs,
            createdAt: nowMs,
          ));
      final cards = await db.select(db.cardStates).get();
      expect(cards.length, 1);
      expect(cards.first.wordId, 'cet4-new');

      await db.close();
    });

    test('card_states UNIQUE(word_id) constraint works', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;

      await db.into(db.cardStates).insert(CardStatesCompanion.insert(
            wordId: 'cet4-dup',
            due: nowMs,
            createdAt: nowMs,
          ));

      // Second insert with same word_id should throw
      expect(
        () => db.into(db.cardStates).insert(CardStatesCompanion.insert(
              wordId: 'cet4-dup',
              due: nowMs,
              createdAt: nowMs,
            )),
        throwsA(isA<Exception>()),
      );

      await db.close();
    });

    test('upgrade from v5: review_records gains rating column (v6, Need #10)', () async {
      // Simulate a v5 database (sessions + review_records WITHOUT rating).
      final nativeDb = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA user_version = 5');
          // Need only the bits the v5→v6 upgrade touches.
          rawDb.execute('''
            CREATE TABLE review_records (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              review_group_id TEXT NOT NULL,
              word_id TEXT NOT NULL,
              action_result TEXT NOT NULL,
              session_id TEXT NULL,
              created_at TEXT NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0
            )
          ''');
          rawDb.execute(
              "INSERT INTO review_records (review_group_id, word_id, action_result, created_at) "
              "VALUES ('g1', 'w1', 'correct', '2026-05-01T00:00:00Z')");
          // Need every other table the schema references so drift's
          // onUpgrade can no-op the v5→v6 ALTER step without complaining
          // about missing tables it expects to query later. We only
          // recreate the ones the migration paths read.
          rawDb.execute('''
            CREATE TABLE word_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              word_id TEXT NOT NULL,
              book_id TEXT NOT NULL,
              study_type TEXT NOT NULL DEFAULT 'new',
              action_result TEXT NOT NULL,
              created_at TEXT NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0,
              session_id TEXT
            )
          ''');
          rawDb.execute('CREATE TABLE wordbook_progress (id INTEGER PRIMARY KEY AUTOINCREMENT, book_id TEXT UNIQUE, total_words INTEGER, completed_words INTEGER, updated_at TEXT)');
          rawDb.execute('CREATE TABLE daily_checkins (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT UNIQUE, checked_in INTEGER, created_at TEXT)');
          rawDb.execute('CREATE TABLE custom_wordbooks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, word_count INTEGER, created_at TEXT)');
          rawDb.execute('CREATE TABLE vocabulary_notebook (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT, meaning TEXT, note TEXT, created_at TEXT)');
          rawDb.execute('CREATE TABLE sessions (id TEXT NOT NULL PRIMARY KEY, kind TEXT NOT NULL, started_at TEXT NOT NULL, ended_at TEXT, duration_seconds INTEGER, session_minutes_target INTEGER NOT NULL DEFAULT 15, cached_validation_status TEXT, synced INTEGER NOT NULL DEFAULT 0)');
        },
      );

      final db = AppDatabase.forTesting(nativeDb);

      // Pre-existing row survives the migration.
      final rows = await db.select(db.reviewRecords).get();
      expect(rows.length, 1);
      expect(rows.first.wordId, 'w1');
      expect(rows.first.rating, isNull);

      // New rows can carry rating.
      await db.into(db.reviewRecords).insert(
            ReviewRecordsCompanion.insert(
              reviewGroupId: 'g2',
              wordId: 'w2',
              actionResult: 'correct',
              createdAt: '2026-05-01T01:00:00Z',
              rating: const Value(3),
            ),
          );
      final after = await (db.select(db.reviewRecords)
            ..where((t) => t.wordId.equals('w2')))
          .getSingle();
      expect(after.rating, 3);

      await db.close();
    });

    test('upgrade is idempotent: pre-existing column does NOT crash migration', () async {
      // Repro for the dev-build skew bug: device sits at user_version=1 yet
      // word_records.session_id was added by some earlier build. The v5
      // branch must skip the addColumn instead of throwing
      // "duplicate column name". This was hit on a real emulator after
      // flutter clean + rerun across schema bumps.
      final nativeDb = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA user_version = 1');
          rawDb.execute('CREATE TABLE word_records (id INTEGER PRIMARY KEY AUTOINCREMENT, word_id TEXT NOT NULL, book_id TEXT NOT NULL, study_type TEXT NOT NULL DEFAULT \'new\', action_result TEXT NOT NULL, created_at TEXT NOT NULL, synced INTEGER NOT NULL DEFAULT 0, session_id TEXT)');
          rawDb.execute('CREATE TABLE wordbook_progress (id INTEGER PRIMARY KEY AUTOINCREMENT, book_id TEXT UNIQUE, total_words INTEGER, completed_words INTEGER, updated_at TEXT)');
          rawDb.execute('CREATE TABLE daily_checkins (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT UNIQUE, checked_in INTEGER, created_at TEXT)');
          rawDb.execute('CREATE TABLE custom_wordbooks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, word_count INTEGER, created_at TEXT)');
          rawDb.execute('CREATE TABLE vocabulary_notebook (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT, meaning TEXT, note TEXT, created_at TEXT)');
        },
      );
      final db = AppDatabase.forTesting(nativeDb);

      // After migration, all v7 tables must exist regardless of dev-build skew.
      expect(await db.select(db.wordRecords).get(), isEmpty);
      expect(await db.select(db.sessions).get(), isEmpty);
      expect(await db.select(db.reviewRecords).get(), isEmpty);
      expect(await db.select(db.wordForms).get(), isEmpty);
      expect(await db.select(db.wordRelations).get(), isEmpty);
      expect(await db.select(db.wordPhrases).get(), isEmpty);

      await db.close();
    });

    test('upgrade is idempotent: pre-existing v5 tables do NOT crash migration',
        () async {
      // Same pattern but with sessions / review_records already present at v1.
      final nativeDb = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA user_version = 1');
          rawDb.execute('CREATE TABLE word_records (id INTEGER PRIMARY KEY AUTOINCREMENT, word_id TEXT NOT NULL, book_id TEXT NOT NULL, study_type TEXT NOT NULL DEFAULT \'new\', action_result TEXT NOT NULL, created_at TEXT NOT NULL, synced INTEGER NOT NULL DEFAULT 0)');
          rawDb.execute('CREATE TABLE wordbook_progress (id INTEGER PRIMARY KEY AUTOINCREMENT, book_id TEXT UNIQUE, total_words INTEGER, completed_words INTEGER, updated_at TEXT)');
          rawDb.execute('CREATE TABLE daily_checkins (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT UNIQUE, checked_in INTEGER, created_at TEXT)');
          rawDb.execute('CREATE TABLE custom_wordbooks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, word_count INTEGER, created_at TEXT)');
          rawDb.execute('CREATE TABLE vocabulary_notebook (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT, meaning TEXT, note TEXT, created_at TEXT)');
          rawDb.execute('CREATE TABLE sessions (id TEXT NOT NULL PRIMARY KEY, kind TEXT NOT NULL, started_at TEXT NOT NULL, ended_at TEXT, duration_seconds INTEGER, session_minutes_target INTEGER NOT NULL DEFAULT 15, cached_validation_status TEXT, synced INTEGER NOT NULL DEFAULT 0)');
        },
      );
      final db = AppDatabase.forTesting(nativeDb);
      // Migration must succeed without "table already exists" or
      // "duplicate column" — sessions stays as the partial pre-existing
      // version, the rest of v5/v6/v7 still completes.
      expect(await db.select(db.sessions).get(), isEmpty);
      expect(await db.select(db.wordForms).get(), isEmpty);
      await db.close();
    });

    test('upgrade from v6: enrichment tables created (v7, Need #11)', () async {
      // Simulate a v6 database (sessions + review_records WITH rating, no
      // enrichment tables yet).
      final nativeDb = NativeDatabase.memory(
        setup: (rawDb) {
          rawDb.execute('PRAGMA user_version = 6');
          // Recreate tables that the v7 migration leaves alone but that
          // drift expects to exist when the connection opens.
          rawDb.execute('CREATE TABLE word_records (id INTEGER PRIMARY KEY AUTOINCREMENT, word_id TEXT NOT NULL, book_id TEXT NOT NULL, study_type TEXT NOT NULL DEFAULT \'new\', action_result TEXT NOT NULL, created_at TEXT NOT NULL, synced INTEGER NOT NULL DEFAULT 0, session_id TEXT)');
          rawDb.execute('CREATE TABLE wordbook_progress (id INTEGER PRIMARY KEY AUTOINCREMENT, book_id TEXT UNIQUE, total_words INTEGER, completed_words INTEGER, updated_at TEXT)');
          rawDb.execute('CREATE TABLE daily_checkins (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT UNIQUE, checked_in INTEGER, created_at TEXT)');
          rawDb.execute('CREATE TABLE custom_wordbooks (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, word_count INTEGER, created_at TEXT)');
          rawDb.execute('CREATE TABLE vocabulary_notebook (id INTEGER PRIMARY KEY AUTOINCREMENT, word TEXT, meaning TEXT, note TEXT, created_at TEXT)');
          rawDb.execute('CREATE TABLE sessions (id TEXT NOT NULL PRIMARY KEY, kind TEXT NOT NULL, started_at TEXT NOT NULL, ended_at TEXT, duration_seconds INTEGER, session_minutes_target INTEGER NOT NULL DEFAULT 15, cached_validation_status TEXT, synced INTEGER NOT NULL DEFAULT 0)');
          rawDb.execute('CREATE TABLE review_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, review_group_id TEXT NOT NULL, word_id TEXT NOT NULL, action_result TEXT NOT NULL, session_id TEXT NULL, created_at TEXT NOT NULL, synced INTEGER NOT NULL DEFAULT 0, rating INTEGER NULL)');
        },
      );
      final db = AppDatabase.forTesting(nativeDb);

      // The 3 new enrichment tables should now exist and be empty.
      expect(await db.select(db.wordForms).get(), isEmpty);
      expect(await db.select(db.wordRelations).get(), isEmpty);
      expect(await db.select(db.wordPhrases).get(), isEmpty);

      // And we can insert into them.
      await db.into(db.wordForms).insert(WordFormsCompanion.insert(
            word: 'abandon',
            formText: 'abandoned',
            formType: 'past',
          ));
      final rows = await db.select(db.wordForms).get();
      expect(rows.length, 1);
      expect(rows.first.formText, 'abandoned');

      await db.close();
    });
  });
}
