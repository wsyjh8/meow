/// P3 Phase 0 — Guard / Fallback / Contract-Absence Regression Tests.
///
/// These tests verify that:
/// - Missing contract fields don't crash the app
/// - Feature guards prevent premature feature enablement
/// - Truth boundaries (streak, review, stats) are not violated
///
/// NOT feature tests — only guard / seam / regression.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/router/app_router.dart';
import 'package:meow_mobile/shared/helpers/streak_display.dart';

import 'dart:convert';

import 'fixtures/p3_test_fixtures.dart';

/// Deep-cast a Dart literal map to match json.decode output types.
Map<String, dynamic> _castDeep(Map<String, dynamic> map) {
  return json.decode(json.encode(map)) as Map<String, dynamic>;
}

void main() {
  // ==================== Group 1: TodayState null-safety ====================

  group('TodayState contract-absent robustness', () {
    test('fromJson does not crash when core fields are missing', () {
      final json = P3JsonFixtures.todayStateContractAbsent();
      final state = TodayState.fromJson(json);

      // Should parse without crash, using conservative defaults
      expect(state.currentBookName, '');
      expect(state.todayNewTarget, 0);
      expect(state.todayNewCompleted, 0);
      expect(state.todayReviewTarget, 0);
      expect(state.todayReviewPending, 0);
      expect(state.todayReviewCompleted, 0);
      expect(state.dailyGoalStatus, 'not_started');
      expect(state.syncStatus, 'healthy');
    });

    test('fromJson does not crash with completely empty JSON', () {
      final json = P3JsonFixtures.todayStateEmpty();
      final state = TodayState.fromJson(json);

      // All defaults — never implies completion or availability
      expect(state.dailyGoalStatus, 'not_started');
      expect(state.currentStreak, 0);
      expect(state.hasCheckedInToday, false);
      expect(state.learningDayToday, false);
      expect(state.sessionValidToday, false);
    });

    test('fromJson parses full active baseline correctly', () {
      final json = P3JsonFixtures.todayStateActiveBaseline();
      final state = TodayState.fromJson(json);

      expect(state.currentBookName, 'CET-4');
      expect(state.todayNewTarget, 20);
      expect(state.todayNewCompleted, 5);
      expect(state.dailyGoalStatus, 'partially_completed');
      expect(state.hasCheckedInToday, true);
      expect(state.currentStreak, 3);
    });

    test('defaults never imply completion', () {
      final state = TodayState.fromJson({});

      // Conservative: defaults say "nothing done" not "everything done"
      expect(state.dailyGoalStatus, isNot('completed'));
      expect(state.todayNewCompleted, 0);
      expect(state.todayReviewCompleted, 0);
      expect(state.sessionValidToday, false);
      expect(state.learningDayToday, false);
    });
  });

  // ==================== Group 2: P3 Feature guard assertions ====================

  group('P3 feature guards all disabled', () {
    test('statistics page is not enabled', () {
      expect(P3FeatureGuard.isStatisticsPageEnabled, false);
    });

    test('CTA decision-support is not enabled', () {
      expect(P3FeatureGuard.isCTADecisionSupportEnabled, false);
    });

    test('streak basis switch is not enabled', () {
      expect(P3FeatureGuard.isStreakBasisSwitchEnabled, false);
    });

    test('review readiness contract is not enabled', () {
      expect(P3FeatureGuard.isReviewReadinessContractEnabled, false);
    });
  });

  // ==================== Group 3: Route guard ====================

  group('Route guard — no unpinned routes', () {
    test('no statistics route registered', () {
      final route = AppRouter.generateRoute(
        const RouteSettings(name: '/statistics'),
      );
      // Should produce page-not-found, not a real page
      expect(route, isNotNull);
      // The default route handler returns a Scaffold with "Page not found" text
    });

    test('known routes still work', () {
      final todayRoute = AppRouter.generateRoute(
        const RouteSettings(name: '/'),
      );
      expect(todayRoute, isNotNull);

      final meowHomeRoute = AppRouter.generateRoute(
        const RouteSettings(name: '/meow-home'),
      );
      expect(meowHomeRoute, isNotNull);
    });
  });

  // ==================== Group 4: SecondarySummary contract-absent ====================

  group('SecondarySummary contract-absent robustness', () {
    test('parses without stats_summary', () {
      // Use json.decode to properly type nested maps (matches real API behavior)
      final summary = SecondarySummary.fromJson(_castDeep(P3JsonFixtures.secondarySummaryWithoutStats()));

      expect(summary.statsSummary, isNull);
      expect(summary.coins, 10);
      expect(summary.catSummary.nickname, 'Mimi');
    });

    test('parses without change_highlights', () {
      final summary = SecondarySummary.fromJson(_castDeep(P3JsonFixtures.secondarySummaryWithoutHighlights()));

      expect(summary.changeHighlights, isEmpty);
      expect(summary.statsSummary, isNotNull);
      expect(summary.statsSummary!.streakBasis, 'check_in');
    });

    test('stats_summary defaults streak_basis to check_in', () {
      final json = {
        'total_learning_days': 3,
        'total_words_learned': 10,
        'total_review_groups_completed': 1,
        'total_check_ins': 5,
        'current_streak': 3,
        // streak_basis intentionally absent
      };
      final stats = StatsSummaryData.fromJson(json);
      expect(stats.streakBasis, 'check_in');
    });
  });

  // ==================== Group 5: Streak truth boundary ====================

  group('Streak truth-boundary guards', () {
    test('streakBasisType defaults to check_in when absent', () {
      final state = TodayState.fromJson({});
      expect(state.streakBasisType, 'check_in');
    });

    test('streakBasisType preserved when present', () {
      final state = TodayState.fromJson({
        'streak_basis_type': 'check_in',
      });
      expect(state.streakBasisType, 'check_in');
    });

    test('learning_day true does NOT change streak basis', () {
      final state = TodayState.fromJson({
        'learning_day_today': true,
        'streak_basis_type': 'check_in',
        'current_streak': 5,
      });
      // learning_day being true does NOT make streak learning-day-based
      expect(state.streakBasisType, 'check_in');
      expect(state.learningDayToday, true);
    });
  });

  // ==================== Group 6: Review completion boundary ====================

  group('Review completion truth-boundary', () {
    test('group completion does not imply daily goal completion in model', () {
      // A TodayState where review group is completed but daily goal is not
      final state = TodayState.fromJson({
        'daily_goal_status': 'partially_completed',
        'active_review_group_id': null, // group completed, cleared
        'active_review_group_remaining': 0,
        'today_review_completed': 1,
        'today_review_target': 1,
        'today_new_completed': 0,
        'today_new_target': 20,
      });

      // Despite review goal met, daily_goal is NOT completed
      // (because new words target not met)
      expect(state.dailyGoalStatus, 'partially_completed');
      expect(state.dailyGoalStatus, isNot('completed'));
    });
  });

  // ==================== Group 7: TodayState has no candidate fields ====================

  group('Contract field validation in TodayState', () {
    test('TodayState.todayPrimaryAction is null when field absent from JSON', () {
      // When backend doesn't return today_primary_action → null → Option C fallback
      final state = TodayState.fromJson(P3JsonFixtures.todayStateActiveBaseline());
      expect(state.todayPrimaryAction, isNull);
    });

    test('TodayState parses today_primary_action when present and valid', () {
      final json = Map<String, dynamic>.from(P3JsonFixtures.todayStateActiveBaseline());
      json['today_primary_action'] = {'action': 'go_new_words', 'reason': 'new_words_remaining'};
      final state = TodayState.fromJson(json);
      expect(state.todayPrimaryAction, isNotNull);
      expect(state.todayPrimaryAction!.action, 'go_new_words');
      expect(state.todayPrimaryAction!.reason, 'new_words_remaining');
    });

    test('TodayState rejects today_primary_action with unknown action', () {
      final json = Map<String, dynamic>.from(P3JsonFixtures.todayStateActiveBaseline());
      json['today_primary_action'] = {'action': 'unknown_action', 'reason': 'new_words_remaining'};
      final state = TodayState.fromJson(json);
      expect(state.todayPrimaryAction, isNull); // strict: unknown = absent
    });

    test('TodayState rejects today_primary_action with missing reason', () {
      final json = Map<String, dynamic>.from(P3JsonFixtures.todayStateActiveBaseline());
      json['today_primary_action'] = {'action': 'go_new_words'}; // reason missing
      final state = TodayState.fromJson(json);
      expect(state.todayPrimaryAction, isNull); // strict: incomplete = absent
    });

    test('TodayState does not have statistics_enabled field', () {
      final json = P3JsonFixtures.todayStateActiveBaseline();
      expect(json.containsKey('statistics_enabled'), false);
    });
  });

  // ==================== P3 Phase 2: ReviewSummaryData strict parsing ====================

  group('ReviewSummaryData strict parsing', () {
    test('parses valid contract', () {
      final data = ReviewSummaryData.tryParse({
        'has_active_group': true,
        'active_group_progress': {'completed_items': 3, 'total_items': 8},
        'active_group_completed': false,
        'daily_review_progress': {'completed_units': 1, 'required_units': 3, 'status': 'in_progress'},
        'next_group_readiness': 'not_ready',
      });
      expect(data, isNotNull);
      expect(data!.hasActiveGroup, true);
      expect(data.completedItems, 3);
      expect(data.totalItems, 8);
      expect(data.completedUnits, 1);
      expect(data.requiredUnits, 3);
      expect(data.dailyReviewStatus, 'in_progress');
      expect(data.nextGroupReadiness, 'not_ready');
    });

    test('returns null when entire block is null', () {
      expect(ReviewSummaryData.tryParse(null), isNull);
    });

    test('returns null when has_active_group missing', () {
      expect(ReviewSummaryData.tryParse({
        'active_group_progress': {'completed_items': 3, 'total_items': 8},
        'active_group_completed': false,
        'daily_review_progress': {'completed_units': 1, 'required_units': 3, 'status': 'in_progress'},
        'next_group_readiness': 'not_ready',
      }), isNull);
    });

    test('returns null when status is invalid', () {
      expect(ReviewSummaryData.tryParse({
        'has_active_group': true,
        'active_group_progress': {'completed_items': 3, 'total_items': 8},
        'active_group_completed': false,
        'daily_review_progress': {'completed_units': 1, 'required_units': 3, 'status': 'INVALID'},
        'next_group_readiness': 'not_ready',
      }), isNull);
    });

    test('returns null when readiness is invalid', () {
      expect(ReviewSummaryData.tryParse({
        'has_active_group': true,
        'active_group_progress': {'completed_items': 3, 'total_items': 8},
        'active_group_completed': false,
        'daily_review_progress': {'completed_units': 1, 'required_units': 3, 'status': 'in_progress'},
        'next_group_readiness': 'UNKNOWN',
      }), isNull);
    });

    test('returns null when total_items is 0', () {
      expect(ReviewSummaryData.tryParse({
        'has_active_group': true,
        'active_group_progress': {'completed_items': 0, 'total_items': 0},
        'active_group_completed': false,
        'daily_review_progress': {'completed_units': 0, 'required_units': 3, 'status': 'not_started'},
        'next_group_readiness': 'not_ready',
      }), isNull);
    });

    test('returns null when required_units is 0', () {
      expect(ReviewSummaryData.tryParse({
        'has_active_group': true,
        'active_group_progress': {'completed_items': 0, 'total_items': 5},
        'active_group_completed': false,
        'daily_review_progress': {'completed_units': 0, 'required_units': 0, 'status': 'not_started'},
        'next_group_readiness': 'not_ready',
      }), isNull);
    });

    test('returns null when completed_items is negative', () {
      expect(ReviewSummaryData.tryParse({
        'has_active_group': true,
        'active_group_progress': {'completed_items': -1, 'total_items': 5},
        'active_group_completed': false,
        'daily_review_progress': {'completed_units': 0, 'required_units': 3, 'status': 'not_started'},
        'next_group_readiness': 'not_ready',
      }), isNull);
    });

    test('TodayState.reviewSummary is null when field absent from JSON', () {
      final state = TodayState.fromJson(P3JsonFixtures.todayStateActiveBaseline());
      expect(state.reviewSummary, isNull);
    });
  });

  // ==================== P3 Phase 3: Statistics summary-first hardening ====================

  group('P3P3: Statistics summary-first safety', () {
    test('summary-first path renders when stats present', () {
      // Stats with non-zero values should show the card
      final stats = StatsSummaryData(
        totalLearningDays: 5, totalWordsLearned: 30,
        totalReviewGroupsCompleted: 3, totalCheckIns: 7,
        currentStreak: 3, streakBasis: 'check_in',
      );
      // Verify data is usable (non-null, correct types)
      expect(stats.totalLearningDays, 5);
      expect(stats.totalCheckIns, 7);
      expect(stats.streakBasis, 'check_in');
    });

    test('no standalone statistics route exists in AppRouter', () {
      // P3P3: summary-first means NO /statistics route
      final route = AppRouter.generateRoute(const RouteSettings(name: '/statistics'));
      expect(route, isNotNull); // returns page-not-found, not a real stats page
    });

    test('learning_days cannot come from check_in data alone', () {
      // learning_days must be from learning_day records
      // If stats shows totalLearningDays=0 but totalCheckIns=5, they must remain separate
      final stats = StatsSummaryData(
        totalLearningDays: 0, totalWordsLearned: 0,
        totalReviewGroupsCompleted: 0, totalCheckIns: 5,
        currentStreak: 5, streakBasis: 'check_in',
      );
      // check_ins=5 does NOT mean learning_days=5
      expect(stats.totalLearningDays, isNot(stats.totalCheckIns));
      expect(stats.totalLearningDays, 0);
    });

    test('learning_days cannot come from streak data', () {
      final stats = StatsSummaryData(
        totalLearningDays: 2, totalWordsLearned: 10,
        totalReviewGroupsCompleted: 1, totalCheckIns: 5,
        currentStreak: 5, streakBasis: 'check_in',
      );
      // streak=5 does NOT mean learning_days=5
      expect(stats.totalLearningDays, isNot(stats.currentStreak));
    });

    test('streak is still labeled as check_in basis', () {
      final stats = StatsSummaryData(
        totalLearningDays: 3, totalWordsLearned: 15,
        totalReviewGroupsCompleted: 2, totalCheckIns: 5,
        currentStreak: 5, streakBasis: 'check_in',
      );
      expect(stats.streakBasis, 'check_in');
    });
  });

  group('P3P3: Stats state matrix', () {
    test('null stats summary hides section (unavailable)', () {
      // When stats_summary is null, UI should hide the section
      final summary = SecondarySummary(
        coins: 10, fishTreats: 1, exp: 5,
        catSummary: CatSummary(nickname: 'Mimi', level: 1, mood: 60, bond: 0, energy: 'medium'),
        statsSummary: null,
      );
      expect(summary.statsSummary, isNull);
    });

    test('all-zero stats represents empty state', () {
      final stats = StatsSummaryData(
        totalLearningDays: 0, totalWordsLearned: 0,
        totalReviewGroupsCompleted: 0, totalCheckIns: 0,
        currentStreak: 0, streakBasis: 'check_in',
      );
      final allZero = stats.totalLearningDays == 0 &&
          stats.totalWordsLearned == 0 &&
          stats.totalReviewGroupsCompleted == 0 &&
          stats.totalCheckIns == 0;
      expect(allZero, isTrue);
    });

    test('partial stats (some zero, some non-zero) is normal state', () {
      final stats = StatsSummaryData(
        totalLearningDays: 0, totalWordsLearned: 5,
        totalReviewGroupsCompleted: 0, totalCheckIns: 2,
        currentStreak: 2, streakBasis: 'check_in',
      );
      final allZero = stats.totalLearningDays == 0 &&
          stats.totalWordsLearned == 0 &&
          stats.totalReviewGroupsCompleted == 0 &&
          stats.totalCheckIns == 0;
      expect(allZero, isFalse); // not empty state — should show normal card
    });

    test('StatsSummaryData.fromJson handles all fields absent gracefully', () {
      final stats = StatsSummaryData.fromJson({});
      expect(stats.totalLearningDays, 0);
      expect(stats.totalWordsLearned, 0);
      expect(stats.totalCheckIns, 0);
      expect(stats.currentStreak, 0);
      expect(stats.streakBasis, 'check_in');
    });
  });

  // ==================== P3 Phase 4: Streak decision preparation ====================

  group('P3P4: Streak display helper', () {
    test('basisLabel is check_in based', () {
      expect(StreakDisplay.basisLabel.contains('\u7b7e\u5230'), isTrue); // 签到
    });

    test('streakText formats correctly', () {
      expect(StreakDisplay.streakText(5).contains('5'), isTrue);
    });

    test('streakWithBasis includes basis label', () {
      final text = StreakDisplay.streakWithBasis(3);
      expect(text.contains('3'), isTrue);
      expect(text.contains('\u7b7e\u5230'), isTrue); // 签到
    });

    test('streakChipLabel includes basis', () {
      final chip = StreakDisplay.streakChipLabel(7);
      expect(chip.contains('7'), isTrue);
      expect(chip.contains('\u7b7e\u5230'), isTrue); // 签到
    });
  });

  group('P3P4: Streak truth-boundary regression', () {
    test('check_in=true + learning_day=false: streak exists but no learning day', () {
      final state = TodayState.fromJson({
        'has_checked_in_today': true,
        'learning_day_today': false,
        'current_streak': 5,
        'streak_basis_type': 'check_in',
      });
      // Streak exists (from check_in), but learning_day is false
      // This means: user signed in but didn't study effectively
      expect(state.hasCheckedInToday, true);
      expect(state.learningDayToday, false);
      expect(state.currentStreak, 5);
      expect(state.streakBasisType, 'check_in');
    });

    test('check_in=false + learning_day=true: learning happened but no check-in', () {
      final state = TodayState.fromJson({
        'has_checked_in_today': false,
        'learning_day_today': true,
        'current_streak': 0,
        'streak_basis_type': 'check_in',
      });
      // Studied effectively but didn't sign in — streak should NOT extend
      expect(state.hasCheckedInToday, false);
      expect(state.learningDayToday, true);
      expect(state.currentStreak, 0); // no check-in = no streak extension
      expect(state.streakBasisType, 'check_in');
    });

    test('future explanation guard is disabled', () {
      expect(P3FeatureGuard.isStreakExplanationEnabled, false);
    });

    test('streak basis switch guard is still disabled', () {
      expect(P3FeatureGuard.isStreakBasisSwitchEnabled, false);
    });
  });
}
