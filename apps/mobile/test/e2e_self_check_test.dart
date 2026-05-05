/// Task 6 — Pre-launch self-check tests.
///
/// End-to-end scenarios that verify the full FSRS pipeline works
/// as a user would experience it.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/memory/fsrs_service.dart';
import 'package:meow_mobile/core/memory/review_rating.dart';
import 'package:meow_mobile/core/memory/session_builder.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

AppDatabase _createTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<void> _seedWords(AppDatabase db, int count) async {
  final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
  await db.batch((batch) {
    // v0.3.0 P1: was cached_words pre-P1, unified content layer post-P1.
    batch.insert(
      db.presetWordbooks,
      PresetWordbooksCompanion.insert(
        slug: 'book-001',
        displayName: 'CET-4',
        totalWords: Value(count),
      ),
      mode: InsertMode.insertOrIgnore,
    );
    for (int i = 1; i <= count; i++) {
      batch.insert(
        db.wordEntries,
        WordEntriesCompanion.insert(
          wordId: 'w$i',
          wordText: 'word$i',
          meaning: '义$i',
          importedAt: nowMs,
        ),
        mode: InsertMode.insertOrIgnore,
      );
      batch.insert(
        db.wordBookAssignments,
        WordBookAssignmentsCompanion.insert(
          wordId: 'w$i',
          bookSlug: 'book-001',
          sortOrder: Value(i),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  });
}

void main() {
  late AppDatabase db;
  late FsrsService fsrs;
  late SessionBuilder builder;

  setUp(() {
    db = _createTestDb();
    fsrs = FsrsService(db: db, desiredRetention: 0.9);
    builder = SessionBuilder(fsrsService: fsrs, db: db);
  });

  tearDown(() async => await db.close());

  group('Task 6 self-check', () {
    test('6.2: daily quota change takes effect immediately', () async {
      await _seedWords(db, 100);
      final now = DateTime.utc(2026, 4, 8, 10, 0, 0);

      // Build with limit=10
      final s1 = await builder.buildTodaySession(
          nowLocal: now, newCardsDailyLimit: 10);
      expect(s1.totalNew, 10);

      // "Change setting to 20" — build again same day
      // Already used 10, so 20-10=10 more new cards available
      final s2 = await builder.buildTodaySession(
          nowLocal: now, newCardsDailyLimit: 20);
      expect(s2.totalNew, 10,
          reason: 'Increasing limit from 10→20 should add 10 more new');
      expect(s2.newCardsRemainingToday, 0);
    });

    test('6.3: review_logs has complete history after 20-card session',
        () async {
      await _seedWords(db, 30);
      final now = DateTime.utc(2026, 4, 8, 10, 0, 0);

      // Build session: 20 new cards
      final session = await builder.buildTodaySession(
          nowLocal: now, newCardsDailyLimit: 20);
      expect(session.totalNew, 20);

      // Rate all 20 cards
      final ratings = [
        ReviewRating.good,
        ReviewRating.easy,
        ReviewRating.hard,
        ReviewRating.again,
      ];
      for (int i = 0; i < session.queue.length; i++) {
        final item = session.queue[i];
        final rating = ratings[i % ratings.length];
        await fsrs.rateCard(item.wordId, rating, nowUtc: now);
      }

      // Verify review_logs
      final logs = await db.select(db.reviewLogs).get();
      expect(logs.length, 20, reason: 'Each rateCard must produce exactly 1 log');

      // Verify each log has required fields populated
      for (final log in logs) {
        expect(log.wordId, isNotEmpty);
        expect(log.rating, inInclusiveRange(1, 4));
        expect(log.reviewTimeUtc, greaterThan(0));
        expect(log.stateBefore, inInclusiveRange(1, 3));
      }

      // Verify card_states reflect final states
      final cards = await db.select(db.cardStates).get();
      expect(cards.length, 20);
    });

    test('6.3: exportReviewLogsAsJsonl has all 20 entries', () async {
      await _seedWords(db, 30);
      final now = DateTime.utc(2026, 4, 8, 10, 0, 0);

      final session = await builder.buildTodaySession(
          nowLocal: now, newCardsDailyLimit: 20);
      for (final item in session.queue) {
        await fsrs.rateCard(item.wordId, ReviewRating.good, nowUtc: now);
      }

      final jsonl = await fsrs.exportReviewLogsAsJsonl();
      final lines =
          jsonl.trim().split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines.length, 20);
    });

    test('6.5: time zone single test pass', () async {
      // Already covered in fsrs_service_test.dart — this is a smoke check
      await _seedWords(db, 50);
      final localEvening = DateTime(2026, 4, 8, 23, 50, 0);

      final session = await builder.buildTodaySession(
          nowLocal: localEvening, newCardsDailyLimit: 5);
      expect(session.totalNew, 5);

      // Next day morning — should not see yesterday's new cards as "new" again
      final localMorning = DateTime(2026, 4, 9, 8, 0, 0);
      final session2 = await builder.buildTodaySession(
          nowLocal: localMorning, newCardsDailyLimit: 5);
      // These should be 5 DIFFERENT new cards (word6-word10)
      final ids1 = session.queue.map((i) => i.wordId).toSet();
      final ids2 = session2.queue.where((i) => i.isNew).map((i) => i.wordId).toSet();
      expect(ids1.intersection(ids2), isEmpty,
          reason: 'Next day new cards should not repeat yesterday');
    });
  });
}
