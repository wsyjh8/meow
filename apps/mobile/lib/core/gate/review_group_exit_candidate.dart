/// review_group_exit_candidate_v1 (FROZEN, P3.3.11)
///
/// Promotes P3.3.10's `review_group_exit_gate_v2` from gate-prerequisite
/// listing to exit-candidate qualified status. "Exit-candidate" means
/// "retirement-qualification preparation stage" — NOT "true exit",
/// NOT "currently safe to exit".
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.11-004: review_group must maintain 4 concurrent layers:
///                 current runtime serving owner, retained fallback anchor,
///                 compatibility anchor, and deprecated candidate.
/// RF-P3.3.11-005: exit-candidate layer permits only 5 allowed classes
///                 (dependency inventory / replacement-readiness markers /
///                 retained-anchor → exit-candidate conditions / fallback
///                 scope judgment / no-overclaim assertions).
/// RF-P3.3.11-006: paths that MUST continue depending on review_group:
///                 active continuation identity, completion gating,
///                 settlement trigger, rollback target, baseline compare,
///                 widened-subset failure fallback, user-visible main
///                 queue ultimate fallback.
library;

/// The 5 allowed classes of work in the exit-candidate layer.
enum ExitCandidateClass {
  /// Class 1: dependency inventory — explicit listing of paths still
  /// dependent on review_group.
  dependencyInventory,

  /// Class 2: replacement-readiness marker — whether replacement path
  /// exists, is verifiable, is explainable. Marker ≠ active replacement.
  replacementReadinessMarker,

  /// Class 3: retained-anchor → exit-candidate conditions — hardened
  /// conditions for when anchor can be narrowed (contract / test / doc /
  /// runtime evidence / boundary guard).
  retainedAnchorToExitCandidateConditions,

  /// Class 4: fallback scope judgment — which rollback/fallback scopes
  /// may eventually narrow very narrowly.
  fallbackScopeJudgment,

  /// Class 5: no-overclaim / no-cleanup assertions — must explicitly
  /// state current-and-not-retired/removed/purged.
  noOverclaimNoCleanupAssertions,
}

abstract final class ReviewGroupExitCandidate {
  /// Current status — exit-candidate qualified, NOT true exit.
  /// Tests assert this contains 'exit_candidate_qualified_not_true_exit'.
  static const String kStatus =
      'exit_candidate_qualified_not_true_exit_not_safe_to_exit';

  /// The 4-layer posture that MUST continue (same as P3.3.9 retained-anchor).
  /// Tests assert length == 4 and all canonical roles present.
  static const List<String> kFourLayersMustContinue = [
    'current_runtime_serving_owner',
    'retained_fallback_anchor',
    'compatibility_anchor',
    'deprecated_candidate',
  ];

  /// Paths that MUST continue depending on review_group.
  /// Tests assert length == 7 and all canonical paths present.
  static const List<String> kPathsStillDependingOnReviewGroup = [
    'active_continuation_identity',
    'current_completion_gating',
    'current_settlement_trigger',
    'rollback_target',
    'baseline_compare_compatibility_anchor',
    'widened_subset_failure_fallback_path',
    'user_visible_main_queue_ultimate_fallback',
  ];

  /// Forbidden claims (extends P3.3.10 v2).
  /// Tests assert canonical forbidden phrases present.
  static const List<String> kForbiddenClaims = [
    'review_group 已退场',
    '已不再使用 review_group',
    'review_group 可直接清理',
    'review_group 已变成 fallback-only',
    '旧 cloud path 可回收',
    'true exit 已开始',
    '现在已经可以清理旧 path',
    'retained anchor 已不再需要',
  ];
}
