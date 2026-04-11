/// phase6_writeback_order_v1 (FROZEN, P3.3.12)
///
/// NEW contract this round. Defines the 6-layer immutable writeback
/// sequence for Phase 6 (the P3.3.12 fuller-cutover absorb-judgment
/// preflight phase). Strictly enforces judgment → execution-ready
/// candidate → execution handoff → runtime truth layer separation.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.12-018: minimum write-back sequence — R2 tech → R3 rules →
///                 R5 UI preflight → R1 absorb/pin → conditional R4
///                 fuller-cutover judgment/execution handoff.
/// RF-P3.3.12-019: only judgment-level expressions allowed.
/// RF-P3.3.12-020: Room 1 absorption conditions.
library;

/// The 6 layers in the phase6 writeback order.
enum WritebackPhase6Layer {
  /// Layer 1: Room 2 tech note (fuller-cutover absorb judgment,
  /// true-exit-gate, uplift-absorb judgment, fact-boundary, transition).
  r2TechNote,

  /// Layer 2: Room 3 rules note (true-exit gate rules, fact-owner
  /// boundary, must-hold/must-escalate, overclaim guardrails).
  r3RulesNote,

  /// Layer 3: Room 5 UI preflight (runtime-truth guardrails,
  /// true-exit-gate UI guidance, uplift-absorb UI guidance,
  /// retained-anchor-aware copy).
  r5UiPreflight,

  /// Layer 4: Room 1 judgment — forms ONLY very narrow fuller-cutover /
  /// true-exit-gate / uplift-absorb judgment handoff.
  r1Judgment,

  /// Layer 5: DB/API writeback to seam/marker/rollback/hold/migration/
  /// observability layer only.
  dbApiWriteback,

  /// Layer 6: Runtime baseline update only if Room 1 separately pins
  /// and next-layer execution evidence exists.
  runtimeBaselineUpdate,
}

abstract final class Phase6WritebackOrder {
  /// 6-step canonical writeback sequence.
  /// Tests assert length == 6 and exact order.
  static const List<String> kWritebackSequence = [
    'r2_tech_note',
    'r3_rules_note',
    'r5_ui_preflight',
    'r1_judgment_handoff_only',
    'db_api_writeback_to_seam_marker_layer_only',
    'runtime_baseline_update_only_if_r1_separately_pins',
  ];

  /// The 5 expressions permitted only at judgment layer this round.
  /// Tests assert length == 5.
  static const List<String> kJudgmentOnlyLayerExpressions = [
    'which_widened_subset_qualifies_for_absorb_judgment',
    'which_review_group_content_qualifies_for_true_exit_gate_judgment',
    'which_db_api_seams_are_uplift_absorb_judgment_ready',
    'how_far_stronger_ingest_currently_advances',
    'when_retained_anchor_rollback_target_become_future_narrowable',
  ];

  /// 6 items that CANNOT be elevated to runtime truth this round.
  /// Tests assert all 6 canonical forbidden items present.
  static const List<String> kForbiddenRuntimeTruthElevation = [
    'full_cutover_completed',
    'review_group_true_exit',
    'active_db_api_uplift_absorbed',
    'final_fact_owner_shift',
    'home_page_route_active_continuation_source_switch',
    'cleanup_old_path_purge',
  ];

  /// Immutable layer separation rule: judgment → execution-ready candidate
  /// → execution handoff → runtime truth. Layer jumping is forbidden.
  /// Tests assert this contains 'jumping_forbidden'.
  static const String kImmutableLayerSeparation =
      'judgment_layer_to_execution_ready_candidate_layer_to_execution_handoff_layer_to_runtime_truth_layer_strictly_separated_jumping_forbidden';

  /// 5 absorption conditions for Room 1 → Room 4 next-round handoff
  /// (RF-P3.3.12-020). All 5 must hold.
  /// Tests assert length == 5 and all canonical conditions.
  static const List<String> kAbsorbToR1ToR4HandoffConditions = [
    'no_overclaim',
    'rollback_hold_fallback_observability_complete',
    'no_home_page_route_active_continuation_final_fact_owner_touch',
    'review_group_remains_current_owner_plus_retained_anchor',
    'uplift_absorb_judgment_not_written_as_active_uplift',
  ];
}
