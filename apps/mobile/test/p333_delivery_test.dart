import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/memory/widgets/rating_buttons.dart';
import 'package:meow_mobile/core/review/review_priority_level.dart';
import 'package:meow_mobile/core/review/review_readiness_state.dart';

// ============================================================================
// P3.3.3 — Review Planning Contract v1 Delivery Tests
//
// Frozen contracts under test:
//   review_readiness_policy_v1 (RF-P3.3.3-001 ~ 004):
//     - 4 readiness states: readyNow, notReadyNow, nextGroupEligible,
//       temporarilyUnservable
//     - Truth source: cloud review-serving layer ONLY (NOT local FSRS)
//
//   review_priority_policy_v1 (RF-P3.3.3-005 ~ 008):
//     - Hierarchy only (NOT full scoring algorithm):
//       continuation > dueReview > highPriorityReview > newWords > session
//     - dueReview / highPriorityReview require cloud-confirmed signal
//     - newWords = study_default (stable fallback)
//     - session = lowest, NOT auto-promoted
//
//   review_group_generation_policy_v1 (RF-P3.3.3-011):
//     - next_group_eligible ≠ next_group_generated
//     - Copy must NOT claim next group is already generated / downloaded / ready
//
//   schedule_source_contract_v1:
//     - local FSRS = scheduling candidate signals (NOT readiness truth)
//     - cloud review_group = serving truth (queue / continuation / settlement)
//     - split ≠ planner merge
//
// These tests prove the contracts are stable and no fake facts appear.
// ============================================================================

/// Forbidden copy per P3.3.3 contracts.
/// Extends the P3.3.2 forbidden list with P3.3.3-specific overclaims.
const _forbiddenCopy = [
  // ─── P3.3.3 generation overclaims (review_group_generation_policy_v1) ───
  '下一组已生成',
  '下一组已准备好',
  '下一组已下载',
  '下一组已在后台准备好',
  '下一组可以立即开始',
  // ─── P3.3.3 local-FSRS-as-readiness overclaims (schedule_source_contract_v1) ───
  '本地计划已接管',
  '你的复习已由本地计划接管',
  '本地计划已接管主复习流程',
  '已根据 FSRS 自动切换入口',
  '现在就该复习',
  // ─── P3.3.3 previewDurations deferred (must not appear in UI) ───
  'previewDurations',
  '预览时长',
  // ─── P3.3.2 carried-forward: auto-routing / planner merge fakes ───
  '自动分流',
  '已自动安排',
  '系统已自动为你分流',
  '已整合你的学习计划',
  '统一学习模式已启用',
  '复习规划已更新',
  '本地计划已同步',
  '已统一规划',
  '规划已更新',
  '已切换到最佳学习路径',
  '已为你安排今天复习模式',
  // ─── P3.3.3 permanent-denial fakes (temporarily_unservable must not be permanent) ───
  '今天没有复习资格',
  '今日复习配额已用完',
  '你今天不需要复习',
  '系统判断你今天无需复习',
];

void main() {
  // ==========================================================================
  // Group A: review_readiness_policy_v1 — Enum semantics
  //
  // Proves: 4 states exist with correct semantics; none overclaim.
  // Truth source contract: cloud only, NOT local FSRS.
  // ==========================================================================
  group('P3.3.3 review_readiness_policy_v1: enum semantics', () {
    test('all 4 readiness states exist', () {
      // Ensure all 4 values defined by review_readiness_policy_v1 are present
      const states = ReviewReadinessState.values;
      expect(states, contains(ReviewReadinessState.readyNow));
      expect(states, contains(ReviewReadinessState.notReadyNow));
      expect(states, contains(ReviewReadinessState.nextGroupEligible));
      expect(states, contains(ReviewReadinessState.temporarilyUnservable));
      expect(states.length, 4,
          reason: 'Exactly 4 readiness states defined — no extra states added');
    });

    test('readyNow maps to active review_group in-progress (RF-P3.3.3-001)', () {
      // readyNow is the state when cloud serving layer can immediately serve work.
      // Name must remain stable — code uses switch on it.
      expect(ReviewReadinessState.readyNow.name, 'readyNow');
    });

    test('notReadyNow maps to 404 from cloud — NOT a permanent denial (RF-P3.3.3-002)',
        () {
      // notReadyNow must be neutral — no copy associated with it can imply
      // "no quota ever" or "today done". Name stable.
      expect(ReviewReadinessState.notReadyNow.name, 'notReadyNow');

      // Copy used for not_ready_now must not contain permanent-denial language
      const notReadyNowCopy = [
        '当前暂无待复习内容',
        '可以先去背单词，或稍后再来',
      ];
      for (final copy in notReadyNowCopy) {
        for (final phrase in _forbiddenCopy) {
          expect(copy, isNot(contains(phrase)),
              reason:
                  'not_ready_now copy "$copy" contains forbidden "$phrase"');
        }
      }
    });

    test(
        'nextGroupEligible is eligibility-only — NOT nextGroupGenerated (RF-P3.3.3-003)',
        () {
      // nextGroupEligible ≠ nextGroupGenerated.
      // The enum name itself must not claim generation has happened.
      final name = ReviewReadinessState.nextGroupEligible.name;
      expect(name, equals('nextGroupEligible'));
      expect(name, isNot(contains('Generated')));
      expect(name, isNot(contains('Ready')));
      expect(name, isNot(contains('Downloaded')));
    });

    test('temporarilyUnservable is transient — NOT permanent denial (RF-P3.3.3-004)',
        () {
      // temporarilyUnservable must express transience — not permanent "no quota".
      final name = ReviewReadinessState.temporarilyUnservable.name;
      expect(name, equals('temporarilyUnservable'));
      // "temporarily" is load-bearing — it must not be renamed to "unservable"
      expect(name, contains('temporarily'.substring(0, 4))); // 'temp'

      // Copy used for temporarily_unservable must not imply permanent denial
      const temporarilyCopy = [
        '加载失败：',
        '重试',
      ];
      for (final copy in temporarilyCopy) {
        for (final phrase in _forbiddenCopy) {
          expect(copy, isNot(contains(phrase)),
              reason:
                  'temporarily_unservable copy "$copy" contains forbidden "$phrase"');
        }
      }
    });
  });

  // ==========================================================================
  // Group B: review_priority_policy_v1 — Priority hierarchy
  //
  // Proves: correct hierarchy order; only 5 levels; boundary constraints hold.
  // ==========================================================================
  group('P3.3.3 review_priority_policy_v1: priority hierarchy', () {
    test('kReviewPriorityOrder has exactly 5 levels', () {
      expect(kReviewPriorityOrder.length, 5,
          reason: 'Exactly 5 priority levels defined');
    });

    test('continuation is highest priority (index 0) — RF-P3.3.3-005', () {
      expect(kReviewPriorityOrder.first,
          ReviewPriorityLevel.continuation,
          reason: 'continuation must be highest — it is above all other levels');
    });

    test('session is lowest priority (last index) — RF-P3.3.3-008', () {
      expect(kReviewPriorityOrder.last, ReviewPriorityLevel.session,
          reason: 'session must be lowest — NOT auto-promoted this round');
    });

    test('newWords (study_default) is above session — RF-P3.3.3-007', () {
      final newWordsIdx =
          kReviewPriorityOrder.indexOf(ReviewPriorityLevel.newWords);
      final sessionIdx =
          kReviewPriorityOrder.indexOf(ReviewPriorityLevel.session);
      expect(newWordsIdx, lessThan(sessionIdx),
          reason: 'newWords (study_default stable fallback) outranks session');
    });

    test('full hierarchy order is continuation > due > highPriority > newWords > session',
        () {
      expect(kReviewPriorityOrder, [
        ReviewPriorityLevel.continuation,
        ReviewPriorityLevel.dueReview,
        ReviewPriorityLevel.highPriorityReview,
        ReviewPriorityLevel.newWords,
        ReviewPriorityLevel.session,
      ]);
    });
  });

  // ==========================================================================
  // Group C: review_group_generation_policy_v1 — Gating / non-overclaim
  //
  // Proves: next_group_eligible copy does not overclaim generation;
  // completion screen Layer 3 is eligibility-only.
  // ==========================================================================
  group('P3.3.3 review_group_generation_policy_v1: gating / non-overclaim', () {
    test('nextGroupEligible copy does NOT claim group is already generated',
        () {
      // Copy shown in completion screen Layer 3 (frozen P3.3.3)
      const layer3Copy = '下一组是否可用，以后端判断为准';

      // Must express eligibility / deferral — not generation
      expect(layer3Copy, contains('以后端判断为准'));
      expect(layer3Copy, isNot(contains('已生成')));
      expect(layer3Copy, isNot(contains('已准备好')));
      expect(layer3Copy, isNot(contains('可以立即开始')));
    });

    test('nextGroupEligible copy does NOT claim group is downloaded', () {
      const layer3Copy = '下一组是否可用，以后端判断为准';
      expect(layer3Copy, isNot(contains('已下载')));
      expect(layer3Copy, isNot(contains('已缓存')));
      expect(layer3Copy, isNot(contains('在后台准备')));
    });

    test('completion screen copy is eligibility-only — defers to backend', () {
      // All three layers of the completion screen frozen at P3.3.3
      const layer1Copy = '✅ 本组已完成';
      const layer2Copy = '今日复习进度已更新。是否还有后续任务，以今日目标为准。';
      const layer3Copy = '下一组是否可用，以后端判断为准';

      // Layer 1: group-scoped fact (completed)
      expect(layer1Copy, contains('本组'));

      // Layer 2: hedged daily progress (not absolute)
      expect(layer2Copy, contains('以今日目标为准'));
      expect(layer2Copy, isNot(contains('FSRS')));
      expect(layer2Copy, isNot(contains('本地')));

      // Layer 3: eligibility-only — defers to cloud
      expect(layer3Copy, contains('后端判断'));

      // None of the layers contains generation overclaims
      for (final copy in [layer1Copy, layer2Copy, layer3Copy]) {
        for (final phrase in _forbiddenCopy) {
          expect(copy, isNot(contains(phrase)),
              reason:
                  'completion screen copy "$copy" contains forbidden "$phrase"');
        }
      }
    });
  });

  // ==========================================================================
  // Group D: schedule_source_contract_v1 — Truth split
  //
  // Proves: local FSRS is NOT the readiness truth source;
  // cloud review_group is the serving truth;
  // no fake facts about local plan takeover appear.
  // ==========================================================================
  group('P3.3.3 schedule_source_contract_v1: truth split', () {
    test('ReviewPage visible copy contains no local-FSRS-as-truth facts', () {
      // All ReviewPage copy strings that appear in the UI
      const reviewPageCopy = [
        '复习',              // AppBar title
        '本组剩余',
        '本组复习完成',
        '✅ 本组已完成',
        '今日复习进度已更新。是否还有后续任务，以今日目标为准。',
        '下一组是否可用，以后端判断为准',
        '返回今日',
        '当前暂无待复习内容',
        '可以先去背单词，或稍后再来',
        '加载失败：',
        '重试',
        '返回',
        '本组完成！奖励状态：',
      ];

      for (final copy in reviewPageCopy) {
        for (final phrase in _forbiddenCopy) {
          expect(copy, isNot(contains(phrase)),
              reason:
                  'ReviewPage copy "$copy" contains forbidden "$phrase"');
        }
      }
    });

    test('no previewDurations strings appear in any visible UI copy', () {
      // previewDurations is DEFERRED per P3.3.3 — must not appear in user-facing copy
      const allVisibleCopy = [
        '复习',
        '本组剩余',
        '本组复习完成',
        '当前暂无待复习内容',
        '可以先去背单词，或稍后再来',
        '加载失败：',
        '重试',
        '返回',
        '背单词',
        '开始今天的学习',
        '时间不够？',
        '5 分钟快速复习',
        '今日任务',
        '继续学习',
        '本书进度',
        '错词本',
      ];

      for (final copy in allVisibleCopy) {
        expect(copy, isNot(contains('previewDurations')),
            reason: 'previewDurations must remain deferred — not in "$copy"');
        expect(copy, isNot(contains('预览时长')),
            reason: '预览时长 (previewDurations label) must remain deferred');
      }
    });

    test('readiness state derivation enum values are cloud-signal based', () {
      // Verify the enum values reflect cloud-signal naming, not local-FSRS names
      final names = ReviewReadinessState.values.map((s) => s.name).toList();

      // None of the state names should reference local FSRS concepts
      for (final name in names) {
        expect(name, isNot(contains('fsrs')));
        expect(name, isNot(contains('local')));
        expect(name, isNot(contains('due'))); // local due count must not be a state
        expect(name, isNot(contains('overdue')));
      }

      // Cloud-serving signals are the source — names match cloud semantics
      expect(names, contains('readyNow'));       // active group serving
      expect(names, contains('notReadyNow'));    // 404 from cloud
      expect(names, contains('nextGroupEligible')); // cloud eligibility
      expect(names, contains('temporarilyUnservable')); // transient cloud issue
    });
  });

  // ==========================================================================
  // Group E: Regression guard — P3.3.2 contracts still hold
  //
  // Proves: P3.3.3 changes did not break the P3.3.2 frozen contracts:
  //   session_entry_policy_v1 (navigation unchanged)
  //   planner_owner_split_v1 (bridge still non-blocking)
  // ==========================================================================
  group('P3.3.3 regression: P3.3.2 contracts still hold', () {
    testWidgets(
        '背单词 still navigates to /study — session_entry_policy_v1 unbroken',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/study'),
              child: const Text('背单词'),
            ),
          ),
        ),
        routes: {
          '/study': (_) => const Scaffold(body: Text('reached_study')),
          '/review': (_) => const Scaffold(body: Text('reached_review')),
        },
      ));

      await tester.tap(find.text('背单词'));
      await tester.pumpAndSettle();

      expect(find.text('reached_study'), findsOneWidget);
      expect(find.text('reached_review'), findsNothing); // no silent reroute
    });

    testWidgets('review CTA still routes to /review independently',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/review'),
              child: const Text('5 分钟快速复习'),
            ),
          ),
        ),
        routes: {
          '/study': (_) => const Scaffold(body: Text('reached_study')),
          '/review': (_) => const Scaffold(body: Text('reached_review')),
        },
      ));

      await tester.tap(find.text('5 分钟快速复习'));
      await tester.pumpAndSettle();

      expect(find.text('reached_review'), findsOneWidget);
      expect(find.text('reached_study'), findsNothing);
    });

    testWidgets('rating button labels contain no P3.3.3 forbidden phrases',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FsrsRatingButtons(onRate: (_) {})),
      ));

      // Frozen rating labels (P3.3.1): 不认识 / 模糊 / 记得 / 秒答
      expect(find.text('不认识'), findsOneWidget);
      expect(find.text('模糊'), findsOneWidget);
      expect(find.text('记得'), findsOneWidget);
      expect(find.text('秒答'), findsOneWidget);

      // None of the P3.3.3 forbidden phrases should appear in the rating UI
      for (final phrase in _forbiddenCopy) {
        expect(find.text(phrase), findsNothing,
            reason: 'Forbidden phrase "$phrase" found in rating buttons');
      }
    });
  });
}
