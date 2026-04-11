/// review_group_retained_anchor_v1 (FROZEN, P3.3.9)
///
/// Extends P3.3.6's `review_group_compatibility_posture_v1` (3-layer)
/// with a 4th role: `retained_fallback_anchor`. This round:
/// `review_group` simultaneously occupies 4 roles.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.9-007: review_group enters dual posture — current runtime
///                owner (for non-cut paths) + retained fallback anchor
///                (for new very narrow seam) + compatibility anchor +
///                deprecated candidate.
///
/// RF-P3.3.9-008: following paths must continue depending on review_group:
///                active continuation identity, current completion gating,
///                current settlement trigger, rollback target, baseline
///                path for non-cutover users/sessions.
///
/// RF-P3.3.9-009: if first-cutover seam triggers stop/hold/rollback,
///                rollback target must be cloud review_group current
///                runtime path.
///
/// RF-P3.3.9-010: forbidden review_group claims — already exited,
///                no longer runtime owner, historical compatibility only,
///                can directly clean old cloud path.
library;

abstract final class ReviewGroupRetainedAnchor {
  /// The 4 roles `review_group` occupies this round.
  /// P3.3.6 defined 3 roles; P3.3.9 adds `retained_fallback_anchor`.
  /// Tests assert this list has exactly 4 entries.
  static const List<String> kFourRoles = [
    'current_runtime_serving_owner',
    'retained_fallback_anchor',
    'compatibility_anchor',
    'deprecated_candidate',
  ];

  /// Canonical 4-role posture status string.
  /// Tests assert all 4 role tags are present in this string.
  static const String kFourRolePostureStatus =
      'runtime_owner_plus_retained_fallback_plus_compatibility_anchor_plus_deprecated_candidate';

  /// Paths that MUST continue depending on `review_group` (RF-P3.3.9-008).
  /// Tests assert all 5 canonical paths are present.
  static const List<String> kPathsStillDependingOnReviewGroup = [
    'active_continuation_identity',
    'current_completion_gating',
    'current_settlement_trigger',
    'rollback_target',
    'baseline_path_for_non_cutover_users_sessions',
  ];

  /// Rollback target — where the seam falls back to when cutover trips.
  /// RF-P3.3.9-009: must be cloud review_group current runtime path.
  static const String kRollbackTarget =
      'cloud_review_group_current_runtime_path';

  /// Forbidden claims (RF-P3.3.9-010).
  /// Tests assert none of these appear in any visible UI copy.
  static const List<String> kForbiddenClaims = [
    'review_group 已退场',
    'review_group 已不再是 runtime owner',
    'review_group 历史兼容 only',
    '可以直接清理旧 cloud path',
    'review_group 已被 local 替代',
  ];
}
