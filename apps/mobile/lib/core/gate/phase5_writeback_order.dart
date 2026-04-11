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
library;

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
