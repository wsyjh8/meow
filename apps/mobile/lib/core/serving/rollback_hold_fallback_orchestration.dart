/// rollback_hold_fallback_orchestration (FROZEN, P3.3.14 — B additive)
///
/// Member 4 of `real_cutover_execution_subset_v1`. Neutral copy matrix
/// + state contract for the rollback / hold / fallback orchestration
/// layer. Tests consult this contract. Runtime ReviewPage does NOT
/// consume this file yet — the state machine is defined but not yet
/// wired. It is made consumable so that when a future round wires it,
/// the contract is already pinned and test-locked.
///
/// This is the machinery that `real_cutover_execution_subset_v1`
/// demands be co-delivered alongside B execution. Per the plan, it is
/// the "co-delivered protection layer" without which B execution is
/// not allowed to ship.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.14-005: B checkpoint allowed execution direction — Member 4.
/// RF-P3.3.14-008: B checkpoint pass gate requires rollback / hold /
///                 observability evidence package.
library;

/// The lifecycle states of the orchestration state machine.
enum RollbackHoldFallbackState {
  /// Normal serving state — cloud `review_group` is the current
  /// runtime truth; no rollback, no hold, no fallback active.
  normalServing,

  /// Hold state — scope expansion is halted. Current serving still
  /// delegates to cloud. No state elevation allowed while in hold.
  hold,

  /// Rollback state — an immediate rollback to the cloud review_group
  /// current runtime path. All candidate paths are suspended.
  rollback,

  /// Fallback state — active fallback to retained anchor; all
  /// continuation paths go through cloud `review_group`.
  fallback,
}

/// Immutable neutral-copy matrix for user-visible messages that may be
/// shown in fallback / hold / rollback states. None of these claim
/// any serving-truth switch or fact-owner shift.
class RollbackHoldFallbackCopyMatrix {
  /// Neutral caption shown when the seam is in hold state.
  final String holdCaption;

  /// Neutral caption shown when the seam is in rollback state.
  final String rollbackCaption;

  /// Neutral caption shown when the seam is in fallback state.
  final String fallbackCaption;

  /// Neutral caption shown in normal serving (usually empty string).
  final String normalCaption;

  const RollbackHoldFallbackCopyMatrix({
    required this.holdCaption,
    required this.rollbackCaption,
    required this.fallbackCaption,
    required this.normalCaption,
  });
}

abstract final class RollbackHoldFallbackOrchestration {
  /// Canonical neutral-copy matrix for P3.3.14. Tests assert exact
  /// string equality for each caption.
  static const RollbackHoldFallbackCopyMatrix kCanonicalCopy =
      RollbackHoldFallbackCopyMatrix(
    holdCaption: '复习暂时保持原节奏',
    rollbackCaption: '复习已回到稳定节奏',
    fallbackCaption: '复习继续按原来的方式进行',
    normalCaption: '',
  );

  /// The 4 canonical states. Tests assert exact cardinality.
  static const List<RollbackHoldFallbackState> kStates = [
    RollbackHoldFallbackState.normalServing,
    RollbackHoldFallbackState.hold,
    RollbackHoldFallbackState.rollback,
    RollbackHoldFallbackState.fallback,
  ];

  /// Default state — `normalServing`. Tests assert this.
  static const RollbackHoldFallbackState kDefaultState =
      RollbackHoldFallbackState.normalServing;

  /// Canonical rollback target (locked). Tests assert exact string.
  static const String kRollbackTarget =
      'cloud_review_group_current_runtime_path';

  /// The 8 rollback triggers — any of these firing must transition to
  /// `rollback` state. Mirrors ReviewServingSeam.kRollbackTriggers.
  /// Tests assert length == 8.
  static const List<String> kRollbackTriggers = [
    'first_cutover_seam_affects_home_word_entry',
    'active_continuation_silent_reroute',
    'review_group_written_as_exited',
    'local_evidence_changed_final_fact',
    'home_route_silently_changed',
    'local_subset_written_as_full_runtime_truth',
    'rollback_path_nonexistent_or_unverifiable',
    'requires_db_schema_or_api_core_semantics_change',
  ];

  /// The 4 hold triggers — any of these firing must transition to
  /// `hold` state. Tests assert length == 4.
  static const List<String> kHoldTriggers = [
    'compare_qa_debug_evidence_unreproducible',
    'user_visible_overclaim_detected',
    'rollback_floor_incomplete',
    'observability_gap',
  ];

  /// State transition rule: from any non-normal state, returning to
  /// `normalServing` requires cloud review_group being reachable and
  /// the offending trigger being cleared.
  /// Tests assert this contains 'cloud_reachable_and_trigger_cleared'.
  static const String kReturnToNormalRule =
      'transition_to_normal_serving_requires_cloud_review_group_reachable_and_'
      'trigger_cleared_no_direct_state_elevation_permitted';

  /// Forbidden transitions — these must never happen.
  /// Tests assert length == 5.
  static const List<String> kForbiddenTransitions = [
    'normal_to_direct_local_serving',
    'rollback_to_local_serving',
    'fallback_into_final_fact_owner_shift',
    'hold_cleared_by_overriding_guardrails',
    'any_state_claiming_review_group_exited',
  ];

  /// Semantic boundary: this layer orchestrates the protective states;
  /// it does NOT advance runtime truth.
  /// Tests assert this contains 'protective_layer_does_not_advance'.
  static const String kSemanticBoundary =
      'protective_layer_does_not_advance_runtime_truth_and_all_transitions_'
      'preserve_cloud_review_group_current_runtime_path_as_rollback_target';
}
