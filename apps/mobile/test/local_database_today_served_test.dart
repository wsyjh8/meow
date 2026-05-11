// Bug 4 — Daily new-word goal must count UNIQUE word_ids served today
// (any action_result), not just `know` masteries. The gate query lives
// in [LocalDatabase.getTodayServedNewWordIds] — these tests pin its
// shape so a future regression on the WHERE clause or the
// local-day → UTC conversion would fail loudly.
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:meow_mobile/core/storage/local_database.dart';

void main() {
  // Use FFI for SQLite in headless tests (desktop).
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // PR-C-α: drift is now the sole schema owner. Tests that exercise
  // LocalDatabase WITHOUT also opening AppDatabase on the same file go
  // through the test-only [initializeForTesting] bridge that emits the
  // v13 schema inline. Production code uses [initialize] (no-op schema).
  setUp(() async {
    // Fresh DB per test so cross-test row leak can't mask a bug.
    await LocalDatabase.deleteDatabase_();
    await LocalDatabase.initializeForTesting();
  });

  test('empty table → returns empty set', () async {
    final ids = await LocalDatabase.instance.getTodayServedNewWordIds();
    expect(ids, isEmpty);
  });

  test('forgot + know mixed today → returns all 5 distinct ids', () async {
    final db = LocalDatabase.instance;
    await db.insertWordRecord(
      wordId: 'w1', bookId: 'b', studyType: 'new', actionResult: 'forgot',
    );
    await db.insertWordRecord(
      wordId: 'w2', bookId: 'b', studyType: 'new', actionResult: 'forgot',
    );
    await db.insertWordRecord(
      wordId: 'w3', bookId: 'b', studyType: 'new', actionResult: 'forgot',
    );
    await db.insertWordRecord(
      wordId: 'w4', bookId: 'b', studyType: 'new', actionResult: 'know',
    );
    await db.insertWordRecord(
      wordId: 'w5', bookId: 'b', studyType: 'new', actionResult: 'know',
    );

    final ids = await db.getTodayServedNewWordIds();
    expect(ids, {'w1', 'w2', 'w3', 'w4', 'w5'});
    expect(ids.length, 5,
        reason: 'forgot must count too — that is the whole point of Bug 4');
  });

  test('same word_id rated twice (forgot → know) → counted once', () async {
    final db = LocalDatabase.instance;
    // First "forgot" — insert
    await db.insertWordRecord(
      wordId: 'w1', bookId: 'b', studyType: 'new', actionResult: 'forgot',
    );
    // Second "know" on the SAME word — insertWordRecord upgrades the
    // existing row in place, so distinct count remains 1.
    await db.insertWordRecord(
      wordId: 'w1', bookId: 'b', studyType: 'new', actionResult: 'know',
    );

    final ids = await db.getTodayServedNewWordIds();
    expect(ids, {'w1'});
  });

  test('records from yesterday are EXCLUDED', () async {
    // Hand-craft a row whose created_at sits just before today's local
    // midnight (i.e. yesterday in user-local time). The legacy
    // insertWordRecord always stamps now() so we have to bypass it.
    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1, hours: 1))
        .toUtc()
        .toIso8601String();

    await LocalDatabase.instance.db.insert('word_records', {
      // PR-C-α: word_records.user_id is NOT NULL post-v13. Tests that
      // bypass insertWordRecord() and write directly must include it.
      'user_id': 'pending-local-guest',
      'word_id': 'old-word',
      'book_id': 'b',
      'study_type': 'new',
      'action_result': 'know',
      'created_at': yesterday,
      'synced': 0,
    });

    // Today's row, definitely inside the window.
    await LocalDatabase.instance.insertWordRecord(
      wordId: 'today-word',
      bookId: 'b',
      studyType: 'new',
      actionResult: 'forgot',
    );

    final ids = await LocalDatabase.instance.getTodayServedNewWordIds();
    expect(ids, {'today-word'});
    expect(ids.contains('old-word'), isFalse,
        reason: 'yesterday must not leak into today\'s served-set');
  });
}
