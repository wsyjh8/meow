import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/memory/review_rating.dart';
import 'package:meow_mobile/spec/pages/spec_review_page.dart';

/// Tests for `session_reinforcement_v1` (need #17) decision logic.
///
/// SpecReviewPage 的复习流程被抽象成 [ReinforcementDecision.compute] 纯函数：
/// 给定 (rating, isFormalRated, currentPositiveStreak, requiredStreak)
/// 输出 (callRateCard, incrementReviewed, requeueCard, cardsNeededBefore,
///        newPositiveStreak)。
///
/// 这些 case 验证了需求 17 的 6 条核心规则：
///   1. 第一次 good   → 锁定 FSRS + 直接计入 reviewed
///   2. 第一次 again  → 锁定 FSRS + 进巩固队列
///   3. again → good → good                  → 巩固完成（rateCard 仅 1 次）
///   4. again → good → hard → good → good    → 中途 hard 重置 streak
///   5. again → easy → easy                  → easy 也算（巩固完成）
///   6. again → good（仅 1 次）              → 仍在巩固中，streak=1
void main() {
  // 这些常量与 _SpecReviewPageState._kRequiredReinforcementStreak 同步。
  const requiredStreak = 2;

  group('ReinforcementDecision (session_reinforcement_v1)', () {
    test('case 1: first good → call rateCard + increment reviewed', () {
      final d = ReinforcementDecision.compute(
        rating: ReviewRating.good,
        isFormalRated: false,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d.callRateCard, isTrue);
      expect(d.incrementReviewed, isTrue);
      expect(d.requeueCard, isFalse);
      expect(d.cardsNeededBefore, isNull);
    });

    test('case 1b: first easy → same as first good', () {
      final d = ReinforcementDecision.compute(
        rating: ReviewRating.easy,
        isFormalRated: false,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d.callRateCard, isTrue);
      expect(d.incrementReviewed, isTrue);
      expect(d.requeueCard, isFalse);
    });

    test('case 2: first again → call rateCard + requeue with delay=3', () {
      final d = ReinforcementDecision.compute(
        rating: ReviewRating.again,
        isFormalRated: false,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d.callRateCard, isTrue);
      expect(d.incrementReviewed, isFalse);
      expect(d.requeueCard, isTrue);
      expect(d.cardsNeededBefore, 3);
    });

    test('case 2b: first hard → call rateCard + requeue with delay=2', () {
      final d = ReinforcementDecision.compute(
        rating: ReviewRating.hard,
        isFormalRated: false,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d.callRateCard, isTrue);
      expect(d.incrementReviewed, isFalse);
      expect(d.requeueCard, isTrue);
      expect(d.cardsNeededBefore, 2);
    });

    test(
        'case 3: again → good → good   '
        'rateCard 仅在第一次调用，第二次 good 后 streak=2 出队', () {
      // step 1: first again
      final d1 = ReinforcementDecision.compute(
        rating: ReviewRating.again,
        isFormalRated: false,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d1.callRateCard, isTrue);

      // step 2: 巩固期 good (streak 0 → 1)
      final d2 = ReinforcementDecision.compute(
        rating: ReviewRating.good,
        isFormalRated: true,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d2.callRateCard, isFalse);
      expect(d2.incrementReviewed, isFalse);
      expect(d2.requeueCard, isTrue);
      expect(d2.newPositiveStreak, 1);

      // step 3: 巩固期 good (streak 1 → 2 → 出队)
      final d3 = ReinforcementDecision.compute(
        rating: ReviewRating.good,
        isFormalRated: true,
        currentPositiveStreak: 1,
        requiredStreak: requiredStreak,
      );
      expect(d3.callRateCard, isFalse);
      expect(d3.incrementReviewed, isTrue);
      expect(d3.requeueCard, isFalse);
      expect(d3.newPositiveStreak, 2);
    });

    test(
        'case 4: again → good → hard → good → good  '
        '中途 hard 让 streak 归零，需重新累计两次 good', () {
      // step 1: first again
      final d1 = ReinforcementDecision.compute(
        rating: ReviewRating.again,
        isFormalRated: false,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d1.callRateCard, isTrue);

      // step 2: 巩固 good (streak 0 → 1)
      final d2 = ReinforcementDecision.compute(
        rating: ReviewRating.good,
        isFormalRated: true,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d2.newPositiveStreak, 1);

      // step 3: 巩固 hard (streak 重置为 0，仍然不调 rateCard)
      final d3 = ReinforcementDecision.compute(
        rating: ReviewRating.hard,
        isFormalRated: true,
        currentPositiveStreak: 1,
        requiredStreak: requiredStreak,
      );
      expect(d3.callRateCard, isFalse);
      expect(d3.incrementReviewed, isFalse);
      expect(d3.requeueCard, isTrue);
      expect(d3.newPositiveStreak, 0);

      // step 4: 巩固 good (streak 0 → 1)
      final d4 = ReinforcementDecision.compute(
        rating: ReviewRating.good,
        isFormalRated: true,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d4.newPositiveStreak, 1);

      // step 5: 巩固 good (streak 1 → 2 → 出队)
      final d5 = ReinforcementDecision.compute(
        rating: ReviewRating.good,
        isFormalRated: true,
        currentPositiveStreak: 1,
        requiredStreak: requiredStreak,
      );
      expect(d5.callRateCard, isFalse);
      expect(d5.incrementReviewed, isTrue);
      expect(d5.requeueCard, isFalse);
    });

    test('case 5: again → easy → easy   easy 与 good 等价计入 streak', () {
      // step 1: first again
      final d1 = ReinforcementDecision.compute(
        rating: ReviewRating.again,
        isFormalRated: false,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d1.callRateCard, isTrue);

      // step 2: 巩固 easy (streak 0 → 1)
      final d2 = ReinforcementDecision.compute(
        rating: ReviewRating.easy,
        isFormalRated: true,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d2.callRateCard, isFalse);
      expect(d2.requeueCard, isTrue);
      expect(d2.newPositiveStreak, 1);

      // step 3: 巩固 easy (streak 1 → 2 → 出队)
      final d3 = ReinforcementDecision.compute(
        rating: ReviewRating.easy,
        isFormalRated: true,
        currentPositiveStreak: 1,
        requiredStreak: requiredStreak,
      );
      expect(d3.callRateCard, isFalse);
      expect(d3.incrementReviewed, isTrue);
      expect(d3.requeueCard, isFalse);
    });

    test('case 6: again → good (仅 1 次) → 仍在巩固队列，streak=1', () {
      // step 1: first again
      final d1 = ReinforcementDecision.compute(
        rating: ReviewRating.again,
        isFormalRated: false,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d1.callRateCard, isTrue);
      expect(d1.requeueCard, isTrue);

      // step 2: 巩固 good (streak 0 → 1，仍未出队)
      final d2 = ReinforcementDecision.compute(
        rating: ReviewRating.good,
        isFormalRated: true,
        currentPositiveStreak: 0,
        requiredStreak: requiredStreak,
      );
      expect(d2.callRateCard, isFalse);       // 不再调 rateCard
      expect(d2.incrementReviewed, isFalse);  // 还没完成
      expect(d2.requeueCard, isTrue);         // 仍要重新入队
      expect(d2.newPositiveStreak, 1);
    });

    // ── 边界 case ────────────────────────────────────────────────────────

    test('boundary: requiredStreak=1 时一次 good 即出队', () {
      final d = ReinforcementDecision.compute(
        rating: ReviewRating.good,
        isFormalRated: true,
        currentPositiveStreak: 0,
        requiredStreak: 1,
      );
      expect(d.incrementReviewed, isTrue);
      expect(d.requeueCard, isFalse);
      expect(d.newPositiveStreak, 1);
    });

    test('boundary: 巩固期 again 让任意非零 streak 归零', () {
      final d = ReinforcementDecision.compute(
        rating: ReviewRating.again,
        isFormalRated: true,
        currentPositiveStreak: 5,
        requiredStreak: requiredStreak,
      );
      expect(d.callRateCard, isFalse);
      expect(d.requeueCard, isTrue);
      expect(d.newPositiveStreak, 0);
    });
  });
}
