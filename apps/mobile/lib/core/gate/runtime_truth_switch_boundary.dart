/// runtime_truth_switch_boundary_v1 (FROZEN, P3.3.9)
///
/// Contract anchor listing the single runtime truth allowed to switch
/// and all runtime truths that MUST remain unchanged this round.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.9-005: following runtime truths must remain unchanged:
///                - home page continues study_default
///                - active continuation independent without silent reroute
///                - review_group continues as current runtime serving owner
///                - final fact/settlement via backend
///                - preview/explanation cannot become committed plan fact
///
/// RF-P3.3.9-006: even if ReviewPage serving seam switches narrowly,
///                must not alter home page summary truth, active
///                continuation high-priority semantics, group completion/
///                settlement truth, reward/daily goal/streak/learning day
///                result expression.
library;

abstract final class RuntimeTruthSwitchBoundary {
  /// The ONLY runtime truth allowed to switch this round.
  /// Tests assert this exact string.
  static const String kOnlyAllowedSwitch = 'review_queue_serving_source';

  /// Runtime truths that MUST remain unchanged.
  /// Tests assert all canonical unchanged truths are present.
  static const List<String> kMustRemainUnchanged = [
    'home_page_home_word_entry_study_default',
    'active_continuation_independent_intake',
    'review_group_current_runtime_serving_owner_main_path_fact',
    'review_summary_completion_settlement_final_fact',
    'reward_ledger_daily_goal_streak_learning_day_final_fact',
    'user_visible_owner_shift_local_serving_enabled_cutover_completed_mode_declaration',
  ];

  /// Switches forbidden this round.
  /// Tests assert all canonical forbidden switches are present.
  static const List<String> kForbiddenSwitches = [
    'home_page_route_switch',
    'active_continuation_source_switch',
    'final_fact_owner_shift',
    'reward_settlement_owner_shift',
    'daily_goal_owner_shift',
    'streak_learning_day_owner_shift',
    'preview_explanation_contract_shift',
  ];

  /// Eligibility requirements before the allowed switch can return
  /// `localNonContinuation`. All must hold.
  /// Tests assert all 4 canonical requirements are present.
  static const List<String> kEligibilityRequirements = [
    'only_in_reviewpage',
    'only_non_continuation_path',
    'only_when_local_serving_candidate_readiness_met',
    'only_when_fallback_rollback_holdnote_observability_all_present',
  ];
}
