/// review_group_true_exit_gate_v1 (FROZEN, P3.3.12)
///
/// Extends P3.3.11's `review_group_exit_candidate_v1` from exit-candidate
/// qualified status to true-exit-gate JUDGMENT status. Key distinction:
/// this is JUDGMENT about qualification to discuss entering the true-exit
/// gate — NOT the initiation of actual true exit.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.12-005: review_group must maintain 4 concurrent layers.
/// RF-P3.3.12-006: 5 condition categories must be met before true-exit
///                 judgment: contract / runtime / test / doc / fallback.
/// RF-P3.3.12-007: 6 still-dependent paths block true exit.
/// RF-P3.3.12-008: true-exit-gate judgment ≠ true exit has begun.
library;

abstract final class ReviewGroupTrueExitGate {
  /// Current status — true-exit-gate qualification discussion, NOT
  /// true exit started.
  /// Tests assert this contains 'true_exit_gate_qualification_discussion'.
  static const String kStatus =
      'true_exit_gate_qualification_discussion_not_true_exit_started';

  /// The 4-layer posture that MUST continue (same as P3.3.9 4-role).
  /// Tests assert length == 4.
  static const List<String> kFourLayersMustContinue = [
    'current_runtime_serving_owner',
    'retained_fallback_anchor',
    'compatibility_anchor',
    'deprecated_candidate',
  ];

  /// 6 still-dependent paths that block review_group from true exit
  /// (RF-P3.3.12-007). Tests assert length == 6 and all canonical items.
  static const List<String> kSixStillDependentPaths = [
    'active_continuation_identity',
    'completion_gating',
    'settlement_trigger',
    'rollback_target',
    'non_cutover_non_upgraded_sessions_baseline_path',
    'compatibility_anchor_qa_baseline_reference',
  ];

  /// 7 missing preconditions (RF-P3.3.12-006).
  /// Tests assert length == 7 and all canonical items.
  static const List<String> kSevenMissingPreconditions = [
    'replacement_path_completeness',
    'active_continuation_independence',
    'completion_settlement_trigger_decoupling',
    'rollback_target_replacement_readiness',
    'compatibility_anchor_retirement_readiness',
    'non_cutover_baseline_path_safety',
    'documentation_test_runtime_evidence_completeness',
  ];

  /// Semantic boundary.
  static const String kSemanticBoundary =
      'ready_to_discuss_true_exit_gate_qualification_not_true_exit_started_or_completed';

  /// Forbidden claims.
  /// Tests assert canonical forbidden phrases present.
  static const List<String> kForbiddenClaims = [
    'review_group 已退场',
    '已不再使用 review_group',
    'review_group 可直接清理',
    'review_group 已变成 fallback-only',
    'retained anchor 已不再需要',
    'rollback target 已变',
    '旧 cloud path 可回收',
    'true exit 已开始',
  ];
}
