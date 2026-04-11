/// review_group_exit_gate_v1 (FROZEN, P3.3.8)
///
/// Prerequisites for a hypothetical future `review_group` exit. This
/// gate does NOT decide exit — it only lists what must be true before
/// the exit decision can even be discussed.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.8-006: review_group continues as current runtime owner +
///                compatibility anchor + deprecated candidate
///                (not retirement).
/// RF-P3.3.8-007: real exit-gate judgment requires 4 prerequisite
///                categories: contract, test, doc, boundary.
/// RF-P3.3.8-008: approaching prerequisites only enables discussion,
///                NOT immediate retirement.
library;

/// The 4 prerequisite categories for a future `review_group` exit.
///
/// ALL 4 categories must be complete before any exit decision can be
/// discussed. This round only LISTS the prerequisites — it does not
/// check whether they are met.
enum ReviewGroupExitPrerequisiteCategory {
  /// Category A — contract prerequisites (what contracts must be pinned).
  contract,

  /// Category B — test prerequisites (what regression tests must exist).
  test,

  /// Category C — doc prerequisites (what documentation must align).
  doc,

  /// Category D — boundary prerequisites (what boundaries must be clear).
  boundary,
}

abstract final class ReviewGroupExitGate {
  /// Current gate status — prerequisites NOT yet met.
  /// This round: the 4 categories are being listed, not checked.
  /// Tests assert status contains 'prerequisites_not_yet_met'.
  static const String kGateStatus = 'prerequisites_not_yet_met';

  /// Contract prerequisites (category A).
  /// What contracts must be pinned before exit can be discussed.
  static const List<String> kContractPrerequisites = [
    'local_serving_candidate_pinned_as_next_layer_contract',
    'fact_ingest_candidate_pinned',
    'routing_compat_pinned',
    'writeback_markers_pinned',
    'reviewpage_source_neutral_state_contract',
    'continuation_summary_helper_source_neutral_wording_contract',
    'fact_settlement_ingest_boundary_contract',
    'migration_rollback_hold_note_contract',
    'deprecated_vs_compatibility_only_asset_inventory',
  ];

  /// Test prerequisites (category B).
  /// What regression tests must exist and be green.
  static const List<String> kTestPrerequisites = [
    'current_runtime_truth_regression',
    'user_visible_forbidden_claims_regression',
    'shadow_parity_evidence_classification_regression',
    'review_group_still_serving_regression',
    'cutover_candidate_no_leak_regression',
    'no_must_hold_mismatches_unresolved',
  ];

  /// Doc prerequisites (category C).
  /// What documentation must be aligned across BR/UI/DB/API/TEST.
  static const List<String> kDocPrerequisites = [
    'br_exit_gate_conditions',
    'ui_source_neutral_rewrite_migration_path',
    'db_api_candidate_seam_documentation',
    'rollback_hold_note_minimum_template',
    'writeback_order_explicit',
  ];

  /// Boundary prerequisites (category D).
  /// What boundaries must be clear and explicit.
  static const List<String> kBoundaryPrerequisites = [
    'final_fact_settlement_owner_still_clear_backend',
    'no_silent_fact_owner_shift',
  ];

  /// Forbidden "already exited" claims.
  /// Tests assert none of these appear in any UI copy or code comment.
  static const List<String> kForbiddenExitClaims = [
    '已退场',
    '即将退场',
    '已不再使用',
    '可直接清理旧 path',
    '已完成旧方案迁移',
    '当前已不再使用 review_group',
    '旧方案即将不可用',
  ];
}
