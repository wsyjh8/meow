/// retained_anchor_to_exit_transition_v1 (FROZEN, P3.3.10)
///
/// Defines the classification between "still-fixed" rollback/anchor
/// items and "future-narrowable" items, plus the canonical ordering
/// rule for any future transition from retained-anchor to exit-candidate.
///
/// ============================================================================
/// Canonical ordering rule
/// ============================================================================
///
///   Replace → Then narrow
///
/// (NEVER narrow → then supplement)
///
/// The dependency paths that currently rely on `review_group` must
/// first be given explicit replacement contracts. Only AFTER that can
/// any fallback/rollback scope be narrowed.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.10-006: transition must prioritize fallback narrowing before
///                 deleting current owner identity.
/// RF-P3.3.10-007: certain paths must continue explicitly depending on
///                 review_group.
/// RF-P3.3.10-014: rollback target must continue pointing to cloud
///                 review_group current runtime path.
/// RF-P3.3.10-015: fallback/rollback can only narrow after retained-
///                 anchor dependency paths are step-by-step replaced.
library;

abstract final class RetainedAnchorToExitTransition {
  /// Canonical ordering rule.
  /// Tests assert this contains 'replace_first_then_narrow'.
  static const String kCanonicalOrderingRule =
      'replace_first_then_narrow_never_narrow_first_then_supplement';

  /// Canonical rollback target — MUST stay at cloud review_group.
  /// Tests assert this equals the canonical P3.3.9 rollback target.
  static const String kStillFixedRollbackTarget =
      'cloud_review_group_current_runtime_path';

  /// Items that MUST remain fixed this round (cannot be narrowed).
  /// Tests assert length == 8 and all canonical items are present.
  static const List<String> kStillFixed = [
    'rollback_target_cloud_review_group_current_runtime_path',
    'current_owner_identity_not_downgradable_to_fallback_only',
    'compatibility_anchor_unchanged',
    'deprecated_candidate_marker_unchanged',
    'active_continuation_identity_unchanged',
    'completion_gating_current_review_group_dependency',
    'settlement_trigger_current_review_group_dependency',
    'non_cutover_baseline_path_current_review_group_fallback',
  ];

  /// Items that MAY become narrowable in the FUTURE (not this round).
  /// P3.3.10 only lists these as candidates for future judgment.
  /// Tests assert length == 5 and all canonical candidates are present.
  static const List<String> kFutureNarrowable = [
    'fallback_rollback_scope_only_after_replacement_paths_complete',
    'which_widened_subset_failure_must_return_to_primary_target',
    'which_paths_can_be_separated_from_review_group_dependency',
    'retained_anchor_responsibilities_narrowing_toward_exit_candidate',
    'secondary_fallback_routing_granularity_distinction',
  ];

  /// Preconditions required BEFORE any fallback/rollback narrowing
  /// can be discussed. Tests assert all 5 canonical preconditions.
  static const List<String> kPreconditionsBeforeNarrowing = [
    'active_continuation_replacement_contract_explicitly_declared',
    'completion_gating_replacement_contract_explicitly_declared',
    'settlement_trigger_replacement_contract_explicitly_declared',
    'non_cutover_baseline_path_explicitly_declared',
    'rollback_still_has_usable_target',
  ];

  /// Stop-conditions that MUST trigger hold if any appear.
  /// Tests assert canonical stop triggers are present.
  static const List<String> kStopConditions = [
    'active_continuation_silent_reroute_to_local_path',
    'local_subset_written_as_current_reviewpage_full_truth',
    'local_evidence_directly_modifying_final_ledger_daily_goal_streak_settlement',
    'home_page_route_planner_aware_auto_routing_rewrite',
    'user_visible_cutover_completed_owner_shift_review_group_exited_overclaim',
    'db_schema_api_core_semantics_change_requirement',
    'rollback_path_nonexistent_unverifiable_unexplainable',
  ];

  /// Canonical meaning: P3.3.10 only DEFINES when qualified for true
  /// exit candidate transition; NOT "now transition".
  /// Tests assert this contains 'not_now_transition'.
  static const String kCanonicalMeaning =
      'p3_3_10_only_defines_when_qualified_for_true_exit_candidate_transition_not_now_transition';
}
