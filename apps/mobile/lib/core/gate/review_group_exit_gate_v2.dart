/// review_group_exit_gate_v2 (FROZEN, P3.3.10)
///
/// Extends P3.3.8's `review_group_exit_gate_v1` (4 prerequisite
/// categories) with a new `runtime` category. Total: 5 prerequisite
/// categories must be met before `review_group` exit can even be
/// discussed.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.10-004: review_group continues as current runtime serving
///                 owner + retained fallback anchor + compatibility
///                 anchor + deprecated candidate.
/// RF-P3.3.10-005: review_group can only enter true exit judgment once
///                 5 prerequisite classes are met: contract, test, doc,
///                 runtime, and boundary.
/// RF-P3.3.10-006: transition from retained anchor to exit candidate
///                 must prioritize fallback narrowing before deleting
///                 current owner identity.
library;

/// The 5 prerequisite categories for a future `review_group` exit.
///
/// P3.3.10 adds the `runtime` category to P3.3.8 v1's 4 categories.
enum ExitGateV2PrerequisiteCategory {
  /// Category A — contract prerequisites (extends P3.3.8 v1).
  contract,

  /// Category B — test prerequisites (extends P3.3.8 v1).
  test,

  /// Category C — doc prerequisites (extends P3.3.8 v1).
  doc,

  /// Category D — runtime prerequisites. NEW in P3.3.10.
  /// All 4 runtime paths (active continuation, completion gating,
  /// settlement trigger, rollback target) must have non-ambiguous
  /// replacement paths before exit can be discussed.
  runtime,

  /// Category E — boundary prerequisites (extends P3.3.8 v1).
  boundary,
}

abstract final class ReviewGroupExitGateV2 {
  /// Gate status — v2 prerequisites NOT yet met. This round: the 5
  /// categories are listed as judgment candidates, not checked.
  /// Tests assert status contains 'v2_prerequisites_not_yet_met'.
  static const String kGateStatus =
      'v2_prerequisites_not_yet_met_judgment_candidates_only';

  /// Contract prerequisites (extends P3.3.8 v1).
  /// New in P3.3.10: fuller-cutover subset, fact-owner boundary,
  /// retained-anchor transition, uplift judgment, write-back order.
  static const List<String> kContractPrerequisitesV2 = [
    // NEW in P3.3.10:
    'fuller_cutover_subset_pinned_as_next_layer_contract',
    'cutover_vs_fact_owner_boundary_v2_pinned',
    'retained_anchor_to_exit_transition_pinned',
    'db_api_uplift_judgment_pinned',
    'writeback_order_pinned_for_p3_3_10',
    // P3.3.8 v1 contracts still required:
    'local_serving_candidate_pinned_as_next_layer_contract',
    'fact_ingest_candidate_pinned',
    'routing_compat_pinned',
    'writeback_markers_pinned',
  ];

  /// Test prerequisites (extends P3.3.8 v1).
  static const List<String> kTestPrerequisitesV2 = [
    // NEW in P3.3.10:
    'continuity_adjacent_subset_regression_long_term_stable',
    'continuity_adjacent_rollback_hold_observability_stable',
    'no_must_hold_mismatches_uncleaned',
    // P3.3.8 v1 tests still required:
    'current_runtime_truth_regression',
    'shadow_parity_evidence_classification_regression',
    'review_group_still_serving_regression',
  ];

  /// Doc prerequisites (extends P3.3.8 v1).
  /// New in P3.3.10: four-piece (BR/UI/DB/API) synchronization.
  static const List<String> kDocPrerequisitesV2 = [
    // NEW in P3.3.10:
    'br_ui_db_api_test_exit_impact_scope_synchronized',
    'rollback_target_hold_note_no_overclaim_copy_synchronized',
    // P3.3.8 v1 docs still required:
    'br_exit_gate_conditions',
    'writeback_order_explicit',
  ];

  /// NEW runtime prerequisites (P3.3.10 only).
  /// All 4 paths must have non-ambiguous replacement paths before exit
  /// can be discussed.
  static const List<String> kRuntimePrerequisitesNewInV2 = [
    'active_continuation_unambiguous_replacement_path',
    'completion_gating_unambiguous_replacement_path',
    'settlement_trigger_unambiguous_replacement_path',
    'rollback_target_still_returnable_repeatable_verifiable',
  ];

  /// Boundary prerequisites (extends P3.3.8 v1).
  static const List<String> kBoundaryPrerequisitesV2 = [
    'final_fact_settlement_owner_still_clear_backend',
    'no_silent_fact_owner_shift',
  ];

  /// Forbidden claims (extends P3.3.8 v1 + P3.3.9's retained-anchor list).
  /// Tests assert none of these appear in any visible UI copy.
  static const List<String> kForbiddenClaims = [
    'review_group 已退场',
    '已不再使用 review_group',
    'review_group 可直接清理',
    'retained anchor 已不再需要',
    'review_group 已变成 fallback-only',
    '旧 cloud path 可回收',
  ];
}
