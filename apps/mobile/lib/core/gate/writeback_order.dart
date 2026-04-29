/// writeback_order.dart (MERGED in P3.3.14 consolidation round)
///
/// Consolidated cross-room writeback order contracts from P3.3.8 (phase3) through P3.3.13 (phase7). Each phase pins the immutable layer separation and writeback sequence for its round. Phase3 = P3.3.8, phase5 = P3.3.11, phase6 = P3.3.12, phase7 = P3.3.13.
///
/// This file was consolidated from 4 original per-round files to
/// reduce gate-file sprawl. Class names and constants are preserved
/// exactly so all existing tests continue to work after updating
/// their import paths.
library;

// ============================================================================
// Merged from: phase3_writeback_and_migration.dart
// ============================================================================
/// phase3_writeback_and_migration_v1 (FROZEN, P3.3.8)
///
/// Defines the write-back order for cross-room Phase 3 work + the
/// minimum required structure for migration, rollback, and hold notes.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.8-012: write-back order is Room 2 → Room 3 → Room 5 → Room 1
///                → Room 4 (Room 4 only executes after Room 1 formal pin).
/// RF-P3.3.8-013: migration/rollback/hold note minimum requirements:
///                  - migration: before / after / staged conditions / synced docs
///                  - rollback: trigger / target / owner / evidence /
///                    explicit no-cut-runtime-truth statement
///                  - hold: trigger / clearance condition
/// RF-P3.3.8-014: mandatory 3-layer separation
///                (runtime_truth / compatibility_only / deprecated_candidate).

/// The 5 rooms in the cross-room Phase 3 write-back order.
///
/// Each room produces a specific write-back artifact, and they MUST
/// be written in this order. No room may skip ahead until the
/// previous room's work is pinned.
enum WritebackRoom {
  /// Order 1 — Room 2 tech candidate note (DB/API candidate seams).
  r2TechCandidateNote,

  /// Order 2 — Room 3 rules note (gate, hold/escalate, fact-boundary).
  r3RulesNote,

  /// Order 3 — Room 5 UI preflight (forbidden claims, source-neutral).
  r5UiPreflight,

  /// Order 4 — Room 1 absorb / pin (unified absorption).
  r1Absorb,

  /// Order 5 — Room 4 execution (only after Room 1 formal pin).
  r4Execution,
}

/// Contract anchor constants for Phase 3 write-back and migration.
abstract final class Phase3WritebackAndMigration {
  /// Canonical write-back order (5 steps).
  /// Tests assert length == 5 and the exact order.
  static const List<String> kWritebackOrder = [
    'r2_tech_candidate_note',
    'r3_rules_note',
    'r5_ui_preflight',
    'r1_absorb_pin',
    'r4_execution',
  ];

  /// Migration note minimum required fields (RF-P3.3.8-013).
  /// Every Phase 3 migration note must contain all 4 of these.
  static const List<String> kMigrationNoteRequiredFields = [
    'before',
    'after',
    'staged_conditions',
    'synced_docs',
  ];

  /// Rollback note minimum required fields (RF-P3.3.8-013).
  /// The last field is an explicit statement that this round has NOT
  /// cut runtime truth — without it, the rollback note is incomplete.
  static const List<String> kRollbackNoteRequiredFields = [
    'rollback_trigger',
    'rollback_target_return_to_cloud_serving_truth',
    'rollback_owner',
    'rollback_evidence',
    'explicit_no_cut_runtime_truth_statement',
  ];

  /// Hold note minimum required fields (RF-P3.3.8-013).
  static const List<String> kHoldNoteRequiredFields = [
    'hold_trigger',
    'hold_clearance_condition',
  ];

  /// Three-layer separation tags reinforcing P3.3.6 `SemanticLayer`.
  ///
  /// This list intentionally omits 'shadow_only_evidence' because
  /// P3.3.8 write-back docs apply only to the top-3 layers. Shadow
  /// evidence stays in its own lane from P3.3.7 and does not enter
  /// write-back.
  static const List<String> kMandatoryLayerSeparation = [
    'runtime_truth',
    'compatibility_only',
    'deprecated_candidate',
  ];

  /// Explicit statement every P3.3.8 rollback note must carry.
  /// Tests assert this is the exact canonical wording.
  static const String kExplicitNoCutRuntimeTruthStatement =
      'this_round_has_not_cut_runtime_truth';
}

// ============================================================================
// Merged from: phase5_writeback_order.dart
// ============================================================================
/// phase5_writeback_order_v1 (FROZEN, P3.3.11)
///
/// Defines the 4-layer immutable writeback ordering for Phase 5 (the
/// P3.3.11 fuller-cutover execution prep phase). Ordering is strictly
/// enforced — no upward skipping allowed.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.11-017: write-back order is Room 2 tech note → Room 3 rules
///                 note → Room 5 UI preflight → Room 1 absorb/pin →
///                 Room 4 execution handoff (if approved).
/// RF-P3.3.11-018: items that may be written as execution-ready /
///                 exit-candidate / uplift-readiness.
/// RF-P3.3.11-019: items that may be absorbed to Room 1 → Room 4
///                 handoff only under specific conditions.
///
/// ============================================================================
/// The 4 immutable layers
/// ============================================================================
///
///   Layer 1: preflight absorb
///   Layer 2: execution-ready candidate absorb
///   Layer 3: Room 1 → Room 4 execution handoff absorb
///   Layer 4: runtime truth absorb
///
/// Ordering is immutable: preflight → candidate → handoff → runtime.
/// No upward skipping allowed.

/// The 4 writeback layers in immutable order.
enum WritebackLayer {
  /// Layer 1: preflight absorb (judgment work absorbed).
  preflight,

  /// Layer 2: execution-ready candidate absorb.
  candidate,

  /// Layer 3: Room 1 → Room 4 execution handoff absorb.
  handoff,

  /// Layer 4: runtime truth absorb.
  runtime,
}

abstract final class Phase5WritebackOrder {
  /// Canonical 6-step writeback sequence (RF-P3.3.11-017).
  /// Tests assert length == 6 and exact order.
  static const List<String> kWritebackSequence = [
    'r2_tech_note',
    'r3_rules_note',
    'r5_ui_preflight',
    'r1_absorb_pin_judgment',
    'db_api_writeback_to_uplift_readiness_candidate_layer_only',
    'runtime_baseline_update_only_if_r1_separately_pins',
  ];

  /// The 4 immutable layers in order.
  /// Tests assert length == 4 and canonical order.
  static const List<String> kImmutableLayerOrder = [
    'layer_1_preflight_absorb',
    'layer_2_execution_ready_candidate_absorb',
    'layer_3_room_1_to_room_4_execution_handoff_absorb',
    'layer_4_runtime_truth_absorb',
  ];

  /// Items that MAY be written as execution-ready / exit-candidate /
  /// uplift-readiness (RF-P3.3.11-018).
  /// Tests assert length == 5 and canonical items present.
  static const List<String> kMayBeWrittenAsCandidate = [
    'widened_subset_cutover_layers',
    'review_group_exit_candidate_content_scope',
    'db_api_seams_at_uplift_readiness',
    'stronger_ingest_binding_current_max_layer',
    'retained_anchor_narrowable_ranges',
  ];

  /// Items that CANNOT be upgraded to runtime truth this round.
  /// Tests assert all canonical forbidden upgrades present.
  static const List<String> kCannotBeUpgradedToRuntimeTruth = [
    'full_cutover_completed',
    'review_group_true_exit',
    'active_db_api_uplift_absorbed',
    'final_fact_owner_shift',
    'home_page_route_or_active_continuation_source_switch',
    'cleanup_old_path_purge',
  ];

  /// Immutable ordering rule.
  /// Tests assert this contains 'no_upward_skipping_allowed'.
  static const String kImmutableOrderingRule =
      'preflight_to_candidate_to_execution_to_runtime_no_upward_skipping_allowed';

  /// Absorption conditions for Room 1 → Room 4 handoff (RF-P3.3.11-019).
  /// All 5 conditions must hold for absorption to be permitted.
  static const List<String> kAbsorbToR1ToR4HandoffConditions = [
    'no_overclaim',
    'rollback_hold_fallback_observability_complete',
    'no_home_page_route_active_continuation_final_fact_owner_touch',
    'review_group_remains_current_owner_plus_retained_anchor',
    'uplift_readiness_not_written_as_active_uplift',
  ];
}

// ============================================================================
// Merged from: phase6_writeback_order.dart
// ============================================================================
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

// ============================================================================
// Merged from: phase7_writeback_order.dart
// ============================================================================
/// phase7_writeback_order_v1 (FROZEN, P3.3.13)
///
/// NEW contract this round. Defines the 6-layer immutable writeback
/// sequence for Phase 7 (the P3.3.13 fuller-cutover execution /
/// true-exit-candidate / DB-API uplift-absorb-readiness execution-
/// preflight phase). Extends the P3.3.12 phase6 pattern while
/// substituting Room 1 judgment-handoff with Room 1 execution-handoff.
/// Strictly enforces execution-ready candidate → true-exit-candidate →
/// uplift-absorb-readiness → runtime truth layer separation.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.13-020: minimum write-back sequence — R2 tech → R3 rules →
///                 R5 UI preflight → R1 execution handoff → conditional
///                 DB/API seam writeback → runtime baseline update
///                 only if R1 separately pins post true-closeout.
/// RF-P3.3.13-021: only execution-ready candidate-level expressions
///                 allowed.
/// RF-P3.3.13-022: Room 1 absorption conditions for Room 4 next-round
///                 handoff.

/// The 6 layers in the phase7 writeback order.
enum WritebackPhase7Layer {
  /// Layer 1: Room 2 tech note (execution subset / true-exit-candidate /
  /// uplift-absorb-readiness boundary, fact-boundary, transition).
  r2TechNote,

  /// Layer 2: Room 3 rules note (true-exit-candidate rules, fact-owner
  /// boundary, must-hold / must-escalate, overclaim guardrails).
  r3RulesNote,

  /// Layer 3: Room 5 UI preflight (runtime-truth guardrails, true-exit-
  /// candidate UI guidance, uplift-absorb-readiness UI guidance,
  /// retained-anchor-aware copy).
  r5UiPreflight,

  /// Layer 4: Room 1 execution-handoff — forms ONLY very narrow
  /// execution-subset-v2 / true-exit-candidate / uplift-absorb-
  /// readiness execution handoff.
  r1ExecutionHandoff,

  /// Layer 5: DB/API writeback to seam / marker / rollback / hold /
  /// migration / observability layer only.
  dbApiWritebackToSeamMarkerLayerOnly,

  /// Layer 6: Runtime baseline update only if Room 1 separately pins
  /// and next-layer execution evidence exists post true-closeout.
  runtimeBaselineUpdate,
}

abstract final class Phase7WritebackOrder {
  /// 6-step canonical writeback sequence.
  /// Tests assert length == 6 and exact order.
  static const List<String> kWritebackSequence = [
    'r2_tech_note',
    'r3_rules_note',
    'r5_ui_preflight',
    'r1_execution_handoff_only',
    'db_api_writeback_to_seam_marker_layer_only',
    'runtime_baseline_update_only_if_r1_separately_pins_post_true_closeout',
  ];

  /// The 5 expressions permitted only at execution-ready candidate
  /// layer this round. Tests assert length == 5.
  static const List<String> kJudgmentOnlyLayerExpressions = [
    'which_widened_subset_qualifies_for_execution_subset_v2',
    'which_review_group_content_qualifies_for_true_exit_candidate',
    'which_db_api_seams_are_uplift_absorb_readiness_ready',
    'how_far_stronger_ingest_currently_advances_toward_absorb_readiness',
    'when_retained_anchor_rollback_target_become_future_narrowable',
  ];

  /// 7 items that CANNOT be elevated to runtime truth this round.
  /// Tests assert all 7 canonical forbidden items present.
  static const List<String> kForbiddenRuntimeTruthElevation = [
    'full_cutover_completed',
    'review_group_true_exit',
    'active_db_api_uplift_absorbed',
    'final_fact_owner_shift',
    'home_page_route_active_continuation_source_switch',
    'cleanup_old_path_purge',
    'runtime_owner_shift_completed',
  ];

  /// Immutable layer separation rule: execution-ready candidate →
  /// true-exit-candidate → uplift-absorb-readiness → runtime truth.
  /// Layer jumping is forbidden.
  /// Tests assert this contains 'jumping_forbidden'.
  static const String kImmutableLayerSeparation =
      'execution_ready_candidate_to_true_exit_candidate_to_uplift_absorb_readiness_must_remain_distinct_from_runtime_truth_jumping_forbidden';

  /// 5 absorption conditions for Room 1 → Room 4 next-round handoff
  /// (RF-P3.3.13-022). All 5 must hold.
  /// Tests assert length == 5 and all canonical conditions.
  static const List<String> kR1ToR4HandoffConditions = [
    'no_overclaim',
    'rollback_hold_fallback_observability_complete',
    'no_home_page_route_active_continuation_final_fact_owner_touch',
    'review_group_remains_current_owner_plus_retained_anchor',
    'uplift_absorb_readiness_not_written_as_active_uplift',
  ];
}

