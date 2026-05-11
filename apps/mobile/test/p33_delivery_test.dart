import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/memory/fsrs_service.dart';
import 'package:meow_mobile/core/memory/review_rating.dart';
import 'package:meow_mobile/core/memory/widgets/rating_buttons.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

AppDatabase _createTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  // =========================================================================
  // Group A: Button labels and canonical order
  // =========================================================================
  group('P3.3.1 button labels and order', () {
    test('exactly 4 configs in defaultRatingConfigs', () {
      expect(defaultRatingConfigs.length, 4);
    });

    test('canonical order: again / hard / good / easy', () {
      expect(defaultRatingConfigs[0].rating, ReviewRating.again);
      expect(defaultRatingConfigs[1].rating, ReviewRating.hard);
      expect(defaultRatingConfigs[2].rating, ReviewRating.good);
      expect(defaultRatingConfigs[3].rating, ReviewRating.easy);
    });

    test('frozen wording: 不认识 / 模糊 / 记得 / 秒答', () {
      expect(defaultRatingConfigs[0].label, '不认识');
      expect(defaultRatingConfigs[1].label, '模糊');
      expect(defaultRatingConfigs[2].label, '记得');
      expect(defaultRatingConfigs[3].label, '秒答');
    });

    test('no fake fact copy in any label or sublabel', () {
      const forbidden = ['掌握', '已会', '会了', '完成', '熟练', '记住了', '奖励'];
      for (final cfg in defaultRatingConfigs) {
        for (final w in forbidden) {
          expect(cfg.label, isNot(contains(w)),
              reason: 'label "${cfg.label}" contains forbidden word "$w"');
          expect(cfg.sublabel, isNot(contains(w)),
              reason: 'sublabel "${cfg.sublabel}" contains forbidden word "$w"');
        }
      }
    });
  });

  // =========================================================================
  // Group B: Binary mapping logic
  // =========================================================================
  group('P3.3.1 binary mapping', () {
    String studyBinary(ReviewRating r) =>
        (r == ReviewRating.good || r == ReviewRating.easy) ? 'know' : 'forgot';

    String reviewBinary(ReviewRating r) =>
        (r == ReviewRating.good || r == ReviewRating.easy) ? 'correct' : 'incorrect';

    test('study: again/hard → forgot, good/easy → know', () {
      expect(studyBinary(ReviewRating.again), 'forgot');
      expect(studyBinary(ReviewRating.hard), 'forgot');
      expect(studyBinary(ReviewRating.good), 'know');
      expect(studyBinary(ReviewRating.easy), 'know');
    });

    test('review: again/hard → incorrect, good/easy → correct', () {
      expect(reviewBinary(ReviewRating.again), 'incorrect');
      expect(reviewBinary(ReviewRating.hard), 'incorrect');
      expect(reviewBinary(ReviewRating.good), 'correct');
      expect(reviewBinary(ReviewRating.easy), 'correct');
    });
  });

  // =========================================================================
  // Group C: FsrsRatingButtons widget — layout, disable, tap mapping
  // =========================================================================
  group('P3.3.1 FsrsRatingButtons widget', () {
    testWidgets('all 4 frozen labels visible', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FsrsRatingButtons(onRate: (_) {})),
      ));
      expect(find.text('不认识'), findsOneWidget);
      expect(find.text('模糊'), findsOneWidget);
      expect(find.text('记得'), findsOneWidget);
      expect(find.text('秒答'), findsOneWidget);
    });

    testWidgets('enabled=false blocks all 4 taps (submit disable / throttle)',
        (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FsrsRatingButtons(
            onRate: (_) => tapCount++,
            enabled: false,
          ),
        ),
      ));
      for (final label in ['不认识', '模糊', '记得', '秒答']) {
        await tester.tap(find.text(label), warnIfMissed: false);
      }
      await tester.pump();
      expect(tapCount, 0);
    });

    testWidgets('不认识 fires ReviewRating.again', (tester) async {
      ReviewRating? got;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FsrsRatingButtons(onRate: (r) => got = r)),
      ));
      await tester.tap(find.text('不认识'));
      await tester.pump();
      expect(got, ReviewRating.again);
    });

    testWidgets('模糊 fires ReviewRating.hard', (tester) async {
      ReviewRating? got;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FsrsRatingButtons(onRate: (r) => got = r)),
      ));
      await tester.tap(find.text('模糊'));
      await tester.pump();
      expect(got, ReviewRating.hard);
    });

    testWidgets('记得 fires ReviewRating.good', (tester) async {
      ReviewRating? got;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FsrsRatingButtons(onRate: (r) => got = r)),
      ));
      await tester.tap(find.text('记得'));
      await tester.pump();
      expect(got, ReviewRating.good);
    });

    testWidgets('秒答 fires ReviewRating.easy', (tester) async {
      ReviewRating? got;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FsrsRatingButtons(onRate: (r) => got = r)),
      ));
      await tester.tap(find.text('秒答'));
      await tester.pump();
      expect(got, ReviewRating.easy);
    });
  });

  // =========================================================================
  // Group D: FSRS bridge — success path + assertable fallback
  // =========================================================================
  group('P3.3.1 FSRS bridge: success + fallback paths', () {
    late AppDatabase db;
    late FsrsService svc;

    setUp(() {
      db = _createTestDb();
      svc = FsrsService.forUser(db: db, userId: 'test-user');
    });

    tearDown(() async => db.close());

    test('initCardForWord creates card (bridge success precondition)', () async {
      final card = await svc.initCardForWord('word-001');
      expect(card.wordId, 'word-001');
      expect(card.state, 1); // State.learning
    });

    test('initCardForWord is idempotent — second call returns same id', () async {
      final a = await svc.initCardForWord('word-001');
      final b = await svc.initCardForWord('word-001');
      expect(a.id, b.id);
    });

    test('initCardForWord + rateCard succeeds (full bridge success path)', () async {
      await svc.initCardForWord('word-002');
      final result = await svc.rateCard('word-002', ReviewRating.good);
      expect(result.wordId, 'word-002');
      expect(result.reps, 1);
    });

    // ASSERTABLE FALLBACK: rateCard without prior initCardForWord throws StateError.
    // In ReviewPage bridge, initCardForWord always runs first (P3.3.1), so this
    // path is only reached on DB errors. Test proves the branch is assertable.
    test('rateCard without init throws StateError (assertable fallback branch)',
        () async {
      expect(
        () => svc.rateCard('word-never-initialized', ReviewRating.good),
        throwsA(isA<StateError>()),
      );
    });

    // Bridge failure is non-blocking: catch block reached, error does NOT rethrow,
    // outer execution continues. Mirrors ReviewPage bridge catch semantics.
    test('bridge failure is catchable and non-blocking', () async {
      var bridgeFired = false;
      try {
        await svc.rateCard('word-never-initialized', ReviewRating.again);
      } catch (_) {
        bridgeFired = true;
        // no rethrow — matches ReviewPage bridge behavior
      }
      expect(bridgeFired, isTrue);
      // If we reach this line, the catch did not block outer execution.
    });
  });
}
