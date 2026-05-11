import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/memory/fsrs_service.dart';
import 'package:meow_mobile/core/memory/session_builder.dart';
import 'package:meow_mobile/core/memory/review_rating.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

AppDatabase _createTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Helper: insert N words into the unified content layer (word_entries +
/// word_book_assignments). v0.3.0 P1: replaces the legacy cached_words
/// fixture which is gone after the v10 migration.
Future<void> _seedCachedWords(AppDatabase db, int count,
    {String bookId = 'book-001'}) async {
  final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
  await db.batch((batch) {
    // Ensure preset_wordbooks row exists (FK target for assignments).
    batch.insert(
      db.presetWordbooks,
      PresetWordbooksCompanion.insert(
        slug: bookId,
        displayName: bookId,
        totalWords: Value(count),
      ),
      mode: InsertMode.insertOrIgnore,
    );
    for (int i = 1; i <= count; i++) {
      // Canonical word_id form (no '' prefix).
      final wordId = 'word$i';
      batch.insert(
        db.wordEntries,
        WordEntriesCompanion.insert(
          wordId: wordId,
          wordText: 'word$i',
          meaning: '释义$i',
          importedAt: nowMs,
        ),
        mode: InsertMode.insertOrIgnore,
      );
      batch.insert(
        db.wordBookAssignments,
        WordBookAssignmentsCompanion.insert(
          wordId: wordId,
          bookSlug: bookId,
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
    fsrs = FsrsService.forUser(
      db: db,
      userId: 'test-user',
      desiredRetention: 0.9,
    );
    builder = SessionBuilder(fsrsService: fsrs, db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SessionBuilder', () {
    test('100 cached words, daily limit 10, no due → 10 new cards', () async {
      await _seedCachedWords(db, 100);
      final now = DateTime.utc(2026, 4, 8, 10, 0, 0);

      final session = await builder.buildTodaySession(
        nowLocal: now,
        newCardsDailyLimit: 10,
      );

      expect(session.totalNew, 10);
      expect(session.totalReview, 0);
      expect(session.totalItems, 10);
      expect(session.newCardsRemainingToday, 0);

      // All items should be new
      expect(session.queue.every((item) => item.isNew), isTrue);

      // Word IDs should be in sort_order (word1, word2, ..., word10)
      expect(session.queue.first.wordId, 'word1');
      expect(session.queue.last.wordId, 'word10');
    });

    test('100 cached words, 20 due cards, daily limit 10 → 10 new + 20 review',
        () async {
      await _seedCachedWords(db, 100);
      final pastTime = DateTime.utc(2026, 4, 7, 10, 0, 0);
      final now = DateTime.utc(2026, 4, 8, 10, 0, 0);

      // Create 20 cards that are due (created yesterday, rated "again" so they re-appear)
      for (int i = 1; i <= 20; i++) {
        await fsrs.initCardForWord('review$i', nowUtc: pastTime);
        // Rate "again" so they stay due
        await fsrs.rateCard('review$i', ReviewRating.again,
            nowUtc: pastTime);
      }

      final session = await builder.buildTodaySession(
        nowLocal: now,
        newCardsDailyLimit: 10,
      );

      expect(session.totalNew, 10);
      expect(session.totalReview, 20);
      expect(session.totalItems, 30);

      // Check interleaving: should roughly follow R,R,R,N pattern
      final firstFour = session.queue.take(4).toList();
      // First 3 should be review, 4th should be new (if enough reviews)
      final reviewCount = firstFour.where((i) => !i.isNew).length;
      final newCount = firstFour.where((i) => i.isNew).length;
      expect(reviewCount, 3, reason: 'First 3 should be review (3:1 ratio)');
      expect(newCount, 1, reason: '4th should be new (3:1 ratio)');
    });

    test('same-day second call does not re-introduce new words', () async {
      await _seedCachedWords(db, 100);
      final now = DateTime.utc(2026, 4, 8, 10, 0, 0);

      // First build: should introduce 10 new words
      final session1 = await builder.buildTodaySession(
        nowLocal: now,
        newCardsDailyLimit: 10,
      );
      expect(session1.totalNew, 10);

      // Second build same day: all 10 new slots already used
      final session2 = await builder.buildTodaySession(
        nowLocal: now,
        newCardsDailyLimit: 10,
      );
      expect(session2.totalNew, 0,
          reason: 'Already introduced 10 new today, no more slots');
      expect(session2.newCardsRemainingToday, 0);
    });

    test('empty cached_words → session with 0 new cards', () async {
      // No words cached at all
      final now = DateTime.utc(2026, 4, 8, 10, 0, 0);

      final session = await builder.buildTodaySession(
        nowLocal: now,
        newCardsDailyLimit: 10,
      );

      expect(session.totalNew, 0);
      expect(session.totalReview, 0);
      expect(session.isEmpty, isTrue);
    });

    test('reviewCardsDailyLimit caps review cards', () async {
      await _seedCachedWords(db, 100);
      final pastTime = DateTime.utc(2026, 4, 7, 10, 0, 0);
      final now = DateTime.utc(2026, 4, 8, 10, 0, 0);

      // Create 30 due cards
      for (int i = 1; i <= 30; i++) {
        await fsrs.initCardForWord('rev$i', nowUtc: pastTime);
        await fsrs.rateCard('rev$i', ReviewRating.again,
            nowUtc: pastTime);
      }

      // Cap review to 10
      final session = await builder.buildTodaySession(
        nowLocal: now,
        newCardsDailyLimit: 5,
        reviewCardsDailyLimit: 10,
      );

      expect(session.totalReview, 10,
          reason: 'Review capped at 10 despite 30 due');
      expect(session.totalNew, 5);
    });
  });
}
