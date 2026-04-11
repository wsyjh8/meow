/// review_serving_seam (FROZEN, P3.3.9)
///
/// The decision layer that sits between `ReviewPage._loadReviewGroup()`
/// and `ApiClient.getNextReviewGroup()`. This round: the seam is
/// consulted for observability, but ALWAYS returns `cloudReviewGroup`
/// because `P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled`
/// is false.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.9-001: only ReviewPage internal serving seam's very narrow
///                subset is allowed for first cutover.
/// RF-P3.3.9-002: first cutover must cut an actual runtime seam, not
///                just helper/copy/state contract changes alone.
/// RF-P3.3.9-007: review_group enters dual posture — current runtime
///                owner + retained fallback anchor + compatibility anchor
///                + deprecated candidate.
/// RF-P3.3.9-008: following paths must continue depending on review_group:
///                active continuation identity, current completion gating,
///                current settlement trigger, rollback target.
/// RF-P3.3.9-009: rollback target = cloud review_group current runtime path.
///
/// ============================================================================
/// Runtime behavior
/// ============================================================================
///
/// This file provides the decision layer only. The actual fetch call
/// (`apiClient.getNextReviewGroup()`) remains in `review_page.dart`
/// unchanged. The seam's only runtime effect is:
///
///   1. A pure-function decision is computed
///   2. The caller logs the decision for observability
///   3. The caller increments an observable counter
///
/// Because the cutover feature flag is OFF this round, the seam ALWAYS
/// returns `cloudReviewGroup`. Runtime behavior is identical to pre-
/// P3.3.9 in every respect.
library;

/// The two kinds of serving sources recognized by the seam.
enum ReviewServingSourceKind {
  /// Current runtime serving source — cloud `review_group`.
  /// This is the ONLY source actually used this round.
  cloudReviewGroup,

  /// First-cutover candidate — local non-continuation serving.
  /// This round: NEVER actually returned because the feature flag is
  /// OFF and the local path is not yet wired.
  localNonContinuation,
}

/// Immutable selection result from the seam.
///
/// Tests assert both the source and the reason to verify the decision
/// path. The `isFallbackToRetainedAnchor` flag marks cases where the
/// seam fell back to `review_group` because either active continuation
/// exists or the local path could not be used.
class ServingSourceSelection {
  /// Which serving source was selected.
  final ReviewServingSourceKind source;

  /// Human-readable reason for the selection. Used in debug logs and
  /// test assertions. Never surfaced to users.
  final String reason;

  /// True when the selection is a fallback to the retained anchor
  /// (cloud `review_group`).
  final bool isFallbackToRetainedAnchor;

  const ServingSourceSelection({
    required this.source,
    required this.reason,
    this.isFallbackToRetainedAnchor = false,
  });
}

/// Pure-function decision layer for `ReviewPage._loadReviewGroup()`.
///
/// No I/O, no mutation, no hidden state. Deterministic — the same
/// inputs always produce the same selection.
abstract final class ReviewServingSeam {
  /// Select the serving source given the cutover flag and active
  /// continuation state.
  ///
  /// Priority order (first matching wins):
  ///   1. active continuation present → cloud (retained anchor)
  ///   2. cutover flag OFF → cloud (default)
  ///   3. cutover flag ON + no continuation → cloud (local path
  ///      not yet wired; fall back with a distinct reason for tests)
  ///
  /// This round: all three paths return `cloudReviewGroup`. The seam
  /// is consulted purely for observability and future wiring.
  static ServingSourceSelection selectSource({
    required bool isCutoverEnabled,
    required bool hasActiveContinuation,
  }) {
    // Priority 1: retained anchor.
    // RF-P3.3.9-008: active continuation identity MUST continue through
    // cloud `review_group`. Even if the flag were ON, we would still
    // go to cloud here.
    if (hasActiveContinuation) {
      return const ServingSourceSelection(
        source: ReviewServingSourceKind.cloudReviewGroup,
        reason: 'retained_anchor_active_continuation',
        isFallbackToRetainedAnchor: true,
      );
    }

    // Priority 2: feature flag OFF.
    if (!isCutoverEnabled) {
      return const ServingSourceSelection(
        source: ReviewServingSourceKind.cloudReviewGroup,
        reason: 'cutover_flag_disabled_default_cloud',
      );
    }

    // Priority 3: flag ON + no continuation — local path would be
    // eligible, but this round the local path is not yet wired.
    // Fall back to cloud with a distinct reason so tests can verify
    // the fallback branch is observable.
    return const ServingSourceSelection(
      source: ReviewServingSourceKind.cloudReviewGroup,
      reason: 'local_path_not_yet_wired_fallback_to_cloud',
      isFallbackToRetainedAnchor: true,
    );
  }

  /// Rollback triggers — if any of these fire, the seam MUST fall back
  /// to the retained anchor immediately.
  /// RF-P3.3.9-016: rollback floor minimum.
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

  /// Hold triggers — if any of these fire, scope expansion MUST stop.
  static const List<String> kHoldTriggers = [
    'compare_qa_debug_evidence_unreproducible',
    'user_visible_overclaim_detected',
    'rollback_floor_incomplete',
    'observability_gap',
  ];

  /// Canonical rollback target — cloud `review_group` current runtime path.
  /// RF-P3.3.9-009: rollback target must be cloud review_group current
  /// runtime path.
  static const String kRollbackTarget =
      'cloud_review_group_current_runtime_path';
}
