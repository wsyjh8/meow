import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/memory/fsrs_service.dart';
import 'package:meow_mobile/core/memory/review_rating.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

/// Creates an in-memory drift database for testing.
AppDatabase _createTestDb() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  const testUserId = 'test-user';
  late AppDatabase db;
  late FsrsService service;

  setUp(() {
    db = _createTestDb();
    service = FsrsService.forUser(
      db: db,
      userId: testUserId,
      desiredRetention: 0.9,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('FsrsService', () {
    test('initCardForWord creates a new card with state=Learning(1) and due≈now',
        () async {
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);
      final card = await service.initCardForWord('cet4-abandon', nowUtc: now);

      expect(card.wordId, 'cet4-abandon');
      expect(card.state, 1); // State.learning
      expect(card.reps, 0);
      expect(card.lapses, 0);
      expect(card.lastReviewUtc, isNull); // never reviewed
      expect(card.dueUtc, now); // due now
    });

    test('initCardForWord is idempotent — second call returns same card',
        () async {
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);
      final card1 = await service.initCardForWord('cet4-abandon', nowUtc: now);
      final card2 = await service.initCardForWord('cet4-abandon', nowUtc: now);

      expect(card1.id, card2.id);
      expect(card1.wordId, card2.wordId);
    });

    test('rateCard(good) advances due date significantly', () async {
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);
      await service.initCardForWord('cet4-test', nowUtc: now);

      // First review: good → should advance through learning steps
      final after = await service.rateCard(
        'cet4-test',
        ReviewRating.good,
        nowUtc: now,
      );

      // After "good" on a new card, due should be pushed forward
      // (at least 10 minutes for learning step 2, or into review state)
      expect(after.dueUtc.isAfter(now), isTrue);
      expect(after.lastReviewUtc, now);
      expect(after.reps, 1); // one successful review
      expect(after.lapses, 0);
    });

    test('rateCard(again) resets reps and increments lapses', () async {
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);
      await service.initCardForWord('cet4-fail', nowUtc: now);

      // First review: good
      await service.rateCard('cet4-fail', ReviewRating.good, nowUtc: now);

      // Second review: again (forgot)
      final later = now.add(const Duration(minutes: 15));
      final afterFail = await service.rateCard(
        'cet4-fail',
        ReviewRating.again,
        nowUtc: later,
      );

      expect(afterFail.reps, 0); // reset on again
      expect(afterFail.lapses, 1); // one lapse
    });

    test('rateCard(good) on Learning card: due pushed to ≥10min (step 2)',
        () async {
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);
      await service.initCardForWord('cet4-step', nowUtc: now);

      // First good → should go to step 1 (10min interval)
      final after = await service.rateCard(
        'cet4-step',
        ReviewRating.good,
        nowUtc: now,
      );

      final dueMinutes = after.dueUtc.difference(now).inMinutes;
      expect(dueMinutes, greaterThanOrEqualTo(10),
          reason: 'After first good, should be ≥10min (learning step 2)');
    });

    test('listDueCards returns cards with due <= now', () async {
      final pastTime = DateTime.utc(2026, 4, 6, 12, 0, 0);
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);

      // Create two cards: one due in the past, one just now
      await service.initCardForWord('cet4-past', nowUtc: pastTime);
      await service.initCardForWord('cet4-now', nowUtc: now);

      // Query as of "now" — both should be due
      final dueCards = await service.listDueCards(nowLocal: now);
      final dueWordIds = dueCards.map((c) => c.wordId).toSet();

      expect(dueWordIds, contains('cet4-past'));
      expect(dueWordIds, contains('cet4-now'));
    });

    test('listDueCards does not return future cards', () async {
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);
      await service.initCardForWord('cet4-now', nowUtc: now);

      // Rate as easy — should push due far into the future
      // First review: good (step 1)
      await service.rateCard('cet4-now', ReviewRating.good, nowUtc: now);
      // Second review: easy (graduates to review, long interval)
      final later = now.add(const Duration(minutes: 15));
      await service.rateCard('cet4-now', ReviewRating.easy, nowUtc: later);

      // Query at the same "later" time — card should not be due
      final dueCards = await service.listDueCards(nowLocal: later);
      final dueWordIds = dueCards.map((c) => c.wordId).toSet();

      expect(dueWordIds, isNot(contains('cet4-now')),
          reason: 'Card rated easy should not be due immediately');
    });

    test('countNewCardsToday counts cards created today', () async {
      final today = DateTime.utc(2026, 4, 7, 10, 0, 0);
      final yesterday = DateTime.utc(2026, 4, 6, 10, 0, 0);

      await service.initCardForWord('cet4-yesterday', nowUtc: yesterday);
      await service.initCardForWord('cet4-today1', nowUtc: today);
      await service.initCardForWord('cet4-today2',
          nowUtc: today.add(const Duration(hours: 2)));

      // Count for today (using local time = UTC in this test)
      final count = await service.countNewCardsToday(nowLocal: today);
      expect(count, 2, reason: 'Only cards created today should count');
    });

    // ==================== Task 3: Review log tests ====================

    test('rateCard inserts exactly one review_log entry per call', () async {
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);
      await service.initCardForWord('cet4-log', nowUtc: now);

      // Before any rating, review_logs should be empty
      final logsBefore = await db.select(db.reviewLogs).get();
      expect(logsBefore, isEmpty);

      // Rate once
      await service.rateCard('cet4-log', ReviewRating.good, nowUtc: now);

      final logsAfter = await db.select(db.reviewLogs).get();
      expect(logsAfter.length, 1);
    });

    test('review_log captures correct state-before and rating', () async {
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);
      await service.initCardForWord('cet4-snap', nowUtc: now);

      // Card starts at state=1 (Learning)
      await service.rateCard('cet4-snap', ReviewRating.hard, nowUtc: now);

      final logs = await db.select(db.reviewLogs).get();
      expect(logs.length, 1);

      final log = logs.first;
      expect(log.wordId, 'cet4-snap');
      expect(log.rating, 2); // hard = 2
      expect(log.stateBefore, 1); // was Learning before review
      expect(log.reviewTimeUtc, now.millisecondsSinceEpoch);
    });

    test('multiple rateCard calls produce multiple review_logs', () async {
      final t0 = DateTime.utc(2026, 4, 7, 12, 0, 0);
      final t1 = t0.add(const Duration(minutes: 5));
      final t2 = t0.add(const Duration(minutes: 15));

      await service.initCardForWord('cet4-multi', nowUtc: t0);

      await service.rateCard('cet4-multi', ReviewRating.good, nowUtc: t0);
      await service.rateCard('cet4-multi', ReviewRating.good, nowUtc: t1);
      await service.rateCard('cet4-multi', ReviewRating.easy, nowUtc: t2);

      final logs = await (db.select(db.reviewLogs)
            ..where((t) => t.wordId.equals('cet4-multi'))
            ..orderBy([(t) => OrderingTerm.asc(t.reviewTimeUtc)]))
          .get();

      expect(logs.length, 3);
      expect(logs[0].rating, 3); // good
      expect(logs[1].rating, 3); // good
      expect(logs[2].rating, 4); // easy
    });

    test('exportReviewLogsAsJsonl outputs valid JSONL', () async {
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);
      await service.initCardForWord('cet4-export', nowUtc: now);
      await service.rateCard('cet4-export', ReviewRating.good, nowUtc: now);

      final jsonl = await service.exportReviewLogsAsJsonl();
      final lines =
          jsonl.trim().split('\n').where((l) => l.isNotEmpty).toList();

      expect(lines.length, 1);

      // Should be valid JSON
      final parsed =
          Map<String, dynamic>.from(jsonDecode(lines.first) as Map);
      expect(parsed['word_id'], 'cet4-export');
      expect(parsed['rating'], 3); // good
      expect(parsed.containsKey('review_time_utc'), isTrue);
      expect(parsed.containsKey('state_before'), isTrue);
      expect(parsed.containsKey('stability_before'), isTrue);
      expect(parsed.containsKey('difficulty_before'), isTrue);
    });

    // ==================== Task 1: Preview tests ====================

    test('previewSchedule returns durations for all 4 ratings', () async {
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);
      await service.initCardForWord('cet4-preview', nowUtc: now);

      final previews =
          await service.previewSchedule('cet4-preview', nowUtc: now);

      expect(previews.length, 4);
      expect(previews.containsKey(ReviewRating.again), isTrue);
      expect(previews.containsKey(ReviewRating.hard), isTrue);
      expect(previews.containsKey(ReviewRating.good), isTrue);
      expect(previews.containsKey(ReviewRating.easy), isTrue);

      // Easy should have the longest interval
      expect(previews[ReviewRating.easy]!.inMinutes,
          greaterThanOrEqualTo(previews[ReviewRating.again]!.inMinutes));
    });

    // ==================== Task 5: Timezone tests ====================
    //
    // Strategy: Dart DateTime has no timezone-aware type.
    // We simulate "UTC+8 local" by constructing non-UTC DateTimes.
    // A user in UTC+8 at local 23:59 on Apr 7 = UTC 15:59 Apr 7.
    // A user in UTC+8 at local 00:01 on Apr 8 = UTC 16:01 Apr 7.

    test('timezone: UTC+8 user at local 23:59 sees cards due that day',
        () async {
      // Card created at UTC 08:00 (= local 16:00 in UTC+8) on Apr 7
      final createdUtc = DateTime.utc(2026, 4, 7, 8, 0, 0);
      await service.initCardForWord('cet4-tz1', nowUtc: createdUtc);

      // Simulate: user queries at "local 23:59 Apr 7" in UTC+8
      // local 23:59 Apr 7 = UTC 15:59 Apr 7
      // We pass this as nowLocal (non-UTC) — listDueCards will call .toUtc()
      final localNight = DateTime(2026, 4, 7, 23, 59, 0);

      final dueCards = await service.listDueCards(nowLocal: localNight);
      final dueIds = dueCards.map((c) => c.wordId).toSet();
      expect(dueIds, contains('cet4-tz1'),
          reason: 'Card due at UTC 08:00 should appear when queried at local 23:59');
    });

    test('timezone: countNewCardsToday respects local day boundary',
        () async {
      // This test is machine-timezone-agnostic.
      // We derive UTC timestamps from local midnight to avoid hardcoded offsets.

      // Local midnight of Apr 8 — the boundary we're testing
      final localMidnight = DateTime(2026, 4, 8, 0, 0, 0);
      final utcMidnight = localMidnight.toUtc();

      // Card A: created 1 hour BEFORE local midnight → belongs to Apr 7
      final beforeUtc = utcMidnight.subtract(const Duration(hours: 1));
      await service.initCardForWord('cet4-before', nowUtc: beforeUtc);

      // Card B: created 1 hour AFTER local midnight → belongs to Apr 8
      final afterUtc = utcMidnight.add(const Duration(hours: 1));
      await service.initCardForWord('cet4-after', nowUtc: afterUtc);

      // Count for "local Apr 7" — only Card A
      final localApr7 = DateTime(2026, 4, 7, 12, 0, 0);
      final countApr7 =
          await service.countNewCardsToday(nowLocal: localApr7);
      expect(countApr7, 1,
          reason: 'Only card before midnight should be in Apr 7');

      // Count for "local Apr 8" — only Card B
      final localApr8 = DateTime(2026, 4, 8, 12, 0, 0);
      final countApr8 =
          await service.countNewCardsToday(nowLocal: localApr8);
      expect(countApr8, 1,
          reason: 'Only card after midnight should be in Apr 8');
    });

    test('timezone: desired_retention change affects preview intervals',
        () async {
      final now = DateTime.utc(2026, 4, 7, 12, 0, 0);
      await service.initCardForWord('cet4-ret', nowUtc: now);

      // Rate good twice to get into Review state (longer intervals)
      await service.rateCard('cet4-ret', ReviewRating.good, nowUtc: now);
      final t1 = now.add(const Duration(minutes: 15));
      await service.rateCard('cet4-ret', ReviewRating.good, nowUtc: t1);

      // Preview with default 0.9
      final preview09 = await service.previewSchedule('cet4-ret', nowUtc: t1);

      // Switch to 0.85 (lower retention → longer intervals)
      service.updateDesiredRetention(0.85);
      final preview085 = await service.previewSchedule('cet4-ret', nowUtc: t1);

      // Switch to 0.95 (higher retention → shorter intervals)
      service.updateDesiredRetention(0.95);
      final preview095 = await service.previewSchedule('cet4-ret', nowUtc: t1);

      // 0.85 should have longer good interval than 0.95
      expect(
        preview085[ReviewRating.good]!.inMinutes,
        greaterThan(preview095[ReviewRating.good]!.inMinutes),
        reason: 'Lower retention (0.85) → longer intervals than higher (0.95)',
      );
    });
  });
}
