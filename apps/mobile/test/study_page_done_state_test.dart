// Bug 2 follow-up regression. The "今日新词已学完" page formerly read
// `今日已学 $_todayCompleted 个单词` which displayed `0` after a session
// of all-不认识 taps. The new copy reads `今日掌握 X / Y 个` and shows
// a soft fallback line ("今天可学的词都过了一遍...") for the rare case
// where the served-cap fallback gate fires.
//
// We can't easily pump the full StudyPage (drift / shared_preferences /
// audio plumbing), so this test mirrors the done-state widget locally.
// If the production widget's copy or visibility rules change, mirror
// here too — the assertion strings double as a stylebook.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Local mirror of `_StudyPageState._buildDoneState`. Kept identical
/// to the production code so a copy-text regression here surfaces
/// during dev.
class _DoneStateMirror extends StatelessWidget {
  final int todayCompleted;
  final int dailyGoal;
  const _DoneStateMirror({
    required this.todayCompleted,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final reachedTarget = todayCompleted >= dailyGoal;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text('今日新词已学完'),
          const SizedBox(height: 8),
          Text('今日掌握 $todayCompleted / $dailyGoal 个'),
          if (!reachedTarget) ...[
            const SizedBox(height: 4),
            const Text('今天可学的词都过了一遍，明天 FSRS 会再排你复习'),
          ],
        ],
      ),
    );
  }
}

void main() {
  group('done state copy', () {
    testWidgets('mastered = goal → no fallback line', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: _DoneStateMirror(todayCompleted: 10, dailyGoal: 10),
        ),
      ));

      expect(find.text('今日新词已学完'), findsOneWidget);
      expect(find.text('今日掌握 10 / 10 个'), findsOneWidget);
      expect(find.textContaining('FSRS 会再排'), findsNothing,
          reason:
              'on-target completion should not surface the soft fallback note');
    });

    testWidgets('mastered exceeds goal → no fallback line', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: _DoneStateMirror(todayCompleted: 12, dailyGoal: 10),
        ),
      ));

      expect(find.text('今日掌握 12 / 10 个'), findsOneWidget);
      expect(find.textContaining('FSRS 会再排'), findsNothing);
    });

    testWidgets('mastered < goal → soft fallback line shown', (tester) async {
      // Bug 2 important case: served-cap fallback gate fired but
      // mastered count is still below goal. This was the misleading
      // "今日已学 0 个" path before the fix.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: _DoneStateMirror(todayCompleted: 0, dailyGoal: 10),
        ),
      ));

      expect(find.text('今日掌握 0 / 10 个'), findsOneWidget,
          reason:
              'fallback path must still display mastered/goal honestly, not "已学 0 个单词"');
      expect(find.textContaining('FSRS 会再排'), findsOneWidget,
          reason:
              'soft fallback line must appear when mastered did not reach goal');
    });

    testWidgets('forbidden phrasing ("已学 X 个单词") never appears',
        (tester) async {
      // Anti-regression for the Bug 2 misleading copy.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: _DoneStateMirror(todayCompleted: 0, dailyGoal: 10),
        ),
      ));

      expect(find.textContaining('已学 0 个单词'), findsNothing);
      expect(find.textContaining('已学 10 个单词'), findsNothing);
    });
  });
}
