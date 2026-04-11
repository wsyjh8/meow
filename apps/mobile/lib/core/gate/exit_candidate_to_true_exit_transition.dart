/// exit_candidate_to_true_exit_transition_v1 (FROZEN, P3.3.12)
///
/// NEW contract this round. Defines the simultaneous preconditions that
/// must hold before any transition from exit-candidate to true-exit-gate
/// can even be DISCUSSED. This is NOT transition execution.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.12-009: retained anchor narrowing only future-discussable if
///                 rollback target has verifiable replacement, active
///                 continuation has stable contract, completion/settlement
///                 gating has non-group-dependent pathways, and
///                 no-overclaim boundaries are synchronized.
/// RF-P3.3.12-016: 5 items must remain fixed (immobile).
/// RF-P3.3.12-017: 4 future-discussable items.
///
/// ============================================================================
/// Canonical rule
/// ============================================================================
///
///   Discussable transition CONDITIONS, not transition execution.
///
/// Current phase only permits discussing the SEVEN simultaneous
/// preconditions; current phase does NOT permit any transition
/// execution itself.
library;

abstract final class ExitCandidateToTrueExitTransition {
  /// Current status — transition conditions discussable, NOT execution.
  /// Tests assert this contains
  /// 'transition_conditions_discussable_not_transition_execution'.
  static const String kStatus =
      'transition_conditions_discussable_not_transition_execution';

  /// 5 items that MUST remain fixed (immobile) this round.
  /// Tests assert length == 5 and all canonical items.
  static const List<String> kFiveImmobileItems = [
    'rollback_target_cloud_review_group_current_runtime_path',
    'current_visible_owner_identity',
    'retained_fallback_anchor_identity',
    'active_continuation_current_path',
    'completion_gating_settlement_trigger_explanation_pathway',
  ];

  /// 7 simultaneous preconditions (all must be concurrently satisfied).
  /// Tests assert length == 7 and all canonical items.
  static const List<String> kSevenSimultaneousPreconditions = [
    'current_owner_explanation_pathway_has_replacement_plan',
    'active_continuation_remains_independent_or_separate_migration',
    'rollback_target_future_replaceable_proof',
    'completion_gating_settlement_trigger_alternative_explanation_pathway',
    'compatibility_anchor_baseline_compare_path_can_migrate',
    'no_cleanup_assertions_remain_valid',
    'regression_runtime_evidence_documentation_readiness_complete_as_suite',
  ];

  /// 4 items that may only be FUTURE-discussed (not this round).
  /// Tests assert length == 4 and canonical items.
  static const List<String> kFutureDiscussableItems = [
    'when_rollback_target_might_become_changeable',
    'when_fallback_scope_might_become_narrower',
    'when_review_group_might_transition_from_current_owner_plus_retained_anchor_posture',
    'which_docs_qa_ui_copy_must_first_decouple_from_group_only_dependency',
  ];

  /// 4 rollback target / fallback scope change conditions (all must coexist).
  /// Tests assert length == 4 and canonical items.
  static const List<String> kRollbackTargetChangeConditions = [
    'replacement_path_has_runtime_evidence',
    'stop_condition_rollback_path_can_be_explained',
    'non_cutover_baseline_path_no_longer_depends_on_current_target',
    'room_1_separately_pins_true_exit_gate_next_round_execution',
  ];

  /// Canonical rule.
  /// Tests assert this contains
  /// 'discussable_transition_conditions_not_transition_execution'.
  static const String kCanonicalRule =
      'discussable_transition_conditions_not_transition_execution_commencing_now';
}
