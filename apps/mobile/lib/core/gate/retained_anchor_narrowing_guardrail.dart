/// retained_anchor_narrowing_guardrail_v1 (FROZEN, P3.3.11)
///
/// Explicit narrowing rules: what CAN be very-narrowly narrowed vs what
/// CANNOT be narrowed. This contract complements P3.3.10's
/// `retained_anchor_to_exit_transition_v1` with more granular execution-
/// ready guardrails.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.11-007: only 5 items may narrow very narrowly; rollback target,
///                 active continuation, completion gating, settlement
///                 trigger, non-cutover baseline remain forbidden.
/// RF-P3.3.11-015: only very-narrow narrowing ranges allowed.
///
/// ============================================================================
/// Canonical rule
/// ============================================================================
///
/// Explanation layer and helper scope MAY narrow.
/// Owner identity, rollback target, completion gating, settlement
/// trigger CANNOT narrow.
library;

abstract final class RetainedAnchorNarrowingGuardrail {
  /// The 5 items that CAN be very-narrowly narrowed this round.
  /// Tests assert length == 5 and all canonical items present.
  static const List<String> kCanNarrowVeryNarrowly = [
    'source_neutral_helper_summary_group_only_wording_coupling',
    'first_page_review_helper_empty_state_no_review_state_retained_anchor_aware_rewrite',
    'rollback_fallback_explanation_historical_redundancy_removal',
    'marker_posture_documentation_ui_docs_expression_layer_optimization',
    'future_narrowable_rollback_bucket_judgment_assessment',
  ];

  /// The 7 items that CANNOT be narrowed (immobile).
  /// Tests assert length == 7 and all canonical items present.
  static const List<String> kCannotNarrow = [
    'rollback_target_cloud_review_group_current_runtime_path',
    'current_runtime_serving_owner_identity',
    'active_continuation_identity',
    'current_completion_gating',
    'current_settlement_trigger',
    'compatibility_anchor',
    'non_cutover_baseline_path',
  ];

  /// Stop conditions that MUST trigger hold/rollback/escalate.
  /// Tests assert length == 7 and all canonical triggers present.
  static const List<String> kStopConditions = [
    'active_continuation_mistakenly_cut_to_local_path',
    'local_subset_written_as_current_reviewpage_full_truth',
    'local_evidence_directly_changes_final_ledger_daily_goal_streak_settlement',
    'home_page_route_changed_to_planner_aware_auto_routing',
    'user_visible_cutover_owner_shift_exit_uplift_overclaim',
    'db_schema_api_core_semantics_change_required',
    'rollback_path_nonexistent_unverifiable_unexplainable',
  ];

  /// Semantic boundary: explanation layer / helper scope narrowable;
  /// owner identity / rollback target / completion gating / settlement
  /// trigger immobile.
  static const String kSemanticBoundary =
      'explanation_layer_helper_scope_may_narrow_owner_identity_rollback_target_completion_gating_settlement_trigger_cannot';
}
