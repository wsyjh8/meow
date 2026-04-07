/// P3 Phase 0 — Shared test fixtures for contract-absent scenarios.
///
/// These fixtures enable testing:
/// - current active baseline behavior
/// - contract-absent fallback (fields missing from JSON)
/// - partial payload degradation
///
/// NOT for testing P3 features — only for guard/seam regression.
library;

import 'package:meow_mobile/core/api/api_client.dart';

/// JSON map fixtures (for testing fromJson parser resilience)
class P3JsonFixtures {
  /// Full active baseline TodayState JSON — all fields present.
  static Map<String, dynamic> todayStateActiveBaseline() => {
    'current_book_name': 'CET-4',
    'today_new_target': 20,
    'today_new_completed': 5,
    'today_review_target': 1,
    'today_review_pending': 0,
    'today_review_completed': 0,
    'daily_goal_status': 'partially_completed',
    'active_review_group_id': null,
    'active_review_group_status': null,
    'active_review_group_remaining': 0,
    'sync_status': 'healthy',
    'last_reward_settlement': null,
    'has_checked_in_today': true,
    'learning_day_today': false,
    'current_streak': 3,
    'streak_basis_type': 'check_in',
    'session_started_today': false,
    'session_valid_today': false,
  };

  /// Minimal TodayState JSON — only Phase 3 optional fields.
  /// Tests that fromJson doesn't crash when core fields are missing.
  static Map<String, dynamic> todayStateContractAbsent() => {
    'has_checked_in_today': false,
    'learning_day_today': false,
    'current_streak': 0,
    'streak_basis_type': 'check_in',
  };

  /// Completely empty JSON — extreme contract-absent scenario.
  static Map<String, dynamic> todayStateEmpty() => {};

  /// SecondarySummary JSON without stats_summary.
  static Map<String, dynamic> secondarySummaryWithoutStats() => {
    'coins': 10,
    'fish_treats': 1,
    'exp': 5,
    'cat_summary': {
      'nickname': 'Mimi',
      'level': 1,
      'mood': 60,
      'bond': 0,
      'energy': 'medium',
    },
    'companion_response': {
      'daily_greeting': 'test greeting',
      'post_learning_response': null,
      'streak_node_response': null,
    },
    'equipped_preview': {},
    'change_highlights': [],
    // stats_summary intentionally absent
  };

  /// SecondarySummary JSON without change_highlights.
  static Map<String, dynamic> secondarySummaryWithoutHighlights() => {
    'coins': 10,
    'fish_treats': 1,
    'exp': 5,
    'cat_summary': {
      'nickname': 'Mimi',
      'level': 1,
      'mood': 60,
      'bond': 0,
      'energy': 'medium',
    },
    'companion_response': {
      'daily_greeting': 'test greeting',
      'post_learning_response': null,
      'streak_node_response': null,
    },
    'equipped_preview': {},
    // change_highlights intentionally absent
    'stats_summary': {
      'total_learning_days': 3,
      'total_words_learned': 15,
      'total_review_groups_completed': 2,
      'total_check_ins': 5,
      'current_streak': 3,
      'streak_basis': 'check_in',
    },
  };
}

/// Model instance fixtures (for widget tests that need pre-built state)
class P3ModelFixtures {
  /// Active baseline TodayState model.
  static TodayState todayStateActive() => TodayState(
    currentBookName: 'CET-4',
    todayNewTarget: 20,
    todayNewCompleted: 5,
    todayReviewTarget: 1,
    todayReviewPending: 0,
    todayReviewCompleted: 0,
    dailyGoalStatus: 'partially_completed',
    activeReviewGroupId: null,
    activeReviewGroupStatus: null,
    activeReviewGroupRemaining: 0,
    syncStatus: 'healthy',
    lastRewardSettlement: null,
    hasCheckedInToday: true,
    learningDayToday: false,
    currentStreak: 3,
    sessionStartedToday: false,
    sessionValidToday: false,
  );

  /// Contract-absent TodayState — all defaults (as if parsed from empty JSON).
  static TodayState todayStateContractAbsent() => TodayState(
    currentBookName: '',
    todayNewTarget: 0,
    todayNewCompleted: 0,
    todayReviewTarget: 0,
    todayReviewPending: 0,
    todayReviewCompleted: 0,
    dailyGoalStatus: 'not_started',
    activeReviewGroupId: null,
    activeReviewGroupStatus: null,
    activeReviewGroupRemaining: 0,
    syncStatus: 'healthy',
    lastRewardSettlement: null,
    hasCheckedInToday: false,
    learningDayToday: false,
    currentStreak: 0,
    sessionStartedToday: false,
    sessionValidToday: false,
  );

  /// SecondarySummary without stats (stats_summary = null).
  static SecondarySummary secondarySummaryNoStats() => SecondarySummary(
    coins: 10, fishTreats: 1, exp: 5,
    catSummary: CatSummary(nickname: 'Mimi', level: 1, mood: 60, bond: 0, energy: 'medium'),
    statsSummary: null,
  );
}
