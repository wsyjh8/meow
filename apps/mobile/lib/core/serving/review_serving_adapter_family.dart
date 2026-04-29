/// review_serving_adapter_family (FROZEN, P3.3.14 — B checkpoint additive)
///
/// Continuity-adjacent serving-adapter family for ReviewPage. This is
/// Member 1 of `real_cutover_execution_subset_v1` and is the only
/// thing in this round that looks like "more real" execution relative
/// to P3.3.13 — it introduces a named family of adapters that sit
/// around the existing `ReviewServingSeam`, each adapter targeting
/// one narrow continuity-adjacent use case.
///
/// **All adapters in this family ALWAYS delegate to cloud `review_group`.**
/// The family exists to make future advancement tractable: a future
/// round can narrowly widen one specific adapter without touching the
/// other continuity paths.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.14-005: B checkpoint allowed execution direction — Member 1.
/// RF-P3.3.14-007: blast radius bounded to ReviewPage + home review
///                 acceptance layer.
/// RF-P3.3.14-017: no final-fact owner shift — adapters must NOT write
///                 final facts.
library;

import 'review_serving_seam.dart';

/// The named continuity-adjacent adapter kinds recognized by the family.
enum ReviewServingAdapterKind {
  /// Continuation-priority adapter — consulted when active continuation
  /// is present. Always returns cloud with retained-anchor reason.
  continuationPriority,

  /// First-load adapter — consulted on the initial load when no
  /// continuation exists. Always returns cloud default.
  firstLoad,

  /// Post-completion refresh adapter — consulted after group completion
  /// when the page reloads for the next group. Always returns cloud.
  postCompletionRefresh,

  /// Fallback adapter — consulted when any of the above report hold /
  /// rollback trigger. Always returns cloud with fallback reason.
  fallback,
}

/// Immutable result of adapter consultation.
class ReviewServingAdapterResult {
  /// Which adapter produced this result.
  final ReviewServingAdapterKind kind;

  /// The underlying seam selection (always cloud this round).
  final ServingSourceSelection selection;

  /// A non-user-visible, test-observable tag used to distinguish
  /// B-checkpoint additive consultation from legacy direct-seam
  /// consultation. Never surfaced to users.
  final String additiveTag;

  const ReviewServingAdapterResult({
    required this.kind,
    required this.selection,
    required this.additiveTag,
  });
}

/// The continuity-adjacent serving-adapter family.
///
/// Pure, deterministic, no I/O. Every `consult*` method delegates to
/// `ReviewServingSeam.selectSource` with explicit continuation state
/// and cutover flag, and wraps the result with a family-specific tag.
///
/// This class is intentionally ABSTRACT FINAL — it has no state, no
/// constructor, and cannot be subclassed. It is a namespace for the
/// 4 named adapter entry points.
abstract final class ReviewServingAdapterFamily {
  /// Additive tag suffix used by all family results. Tests assert that
  /// adapter results carry this substring.
  static const String kAdditiveTagPrefix =
      'p3_3_14_b_additive_adapter_family';

  /// The 4 canonical adapter kinds this family supports. Tests assert
  /// exact cardinality.
  static const List<ReviewServingAdapterKind> kSupportedKinds = [
    ReviewServingAdapterKind.continuationPriority,
    ReviewServingAdapterKind.firstLoad,
    ReviewServingAdapterKind.postCompletionRefresh,
    ReviewServingAdapterKind.fallback,
  ];

  /// Consult the continuation-priority adapter.
  /// Always returns cloud; if `hasActiveContinuation` is true, the
  /// underlying seam marks the result as retained-anchor fallback.
  static ReviewServingAdapterResult consultContinuationPriority({
    required bool isCutoverEnabled,
    required bool hasActiveContinuation,
  }) {
    return ReviewServingAdapterResult(
      kind: ReviewServingAdapterKind.continuationPriority,
      selection: ReviewServingSeam.selectSource(
        isCutoverEnabled: isCutoverEnabled,
        hasActiveContinuation: hasActiveContinuation,
      ),
      additiveTag: '${kAdditiveTagPrefix}_continuation_priority',
    );
  }

  /// Consult the first-load adapter. Always returns cloud default
  /// (no continuation, flag off).
  static ReviewServingAdapterResult consultFirstLoad({
    required bool isCutoverEnabled,
  }) {
    return ReviewServingAdapterResult(
      kind: ReviewServingAdapterKind.firstLoad,
      selection: ReviewServingSeam.selectSource(
        isCutoverEnabled: isCutoverEnabled,
        hasActiveContinuation: false,
      ),
      additiveTag: '${kAdditiveTagPrefix}_first_load',
    );
  }

  /// Consult the post-completion refresh adapter. Always returns cloud.
  static ReviewServingAdapterResult consultPostCompletionRefresh({
    required bool isCutoverEnabled,
  }) {
    return ReviewServingAdapterResult(
      kind: ReviewServingAdapterKind.postCompletionRefresh,
      selection: ReviewServingSeam.selectSource(
        isCutoverEnabled: isCutoverEnabled,
        hasActiveContinuation: false,
      ),
      additiveTag: '${kAdditiveTagPrefix}_post_completion_refresh',
    );
  }

  /// Consult the fallback adapter. Always returns cloud; the result
  /// is marked `isFallbackToRetainedAnchor = true`.
  static ReviewServingAdapterResult consultFallback() {
    return const ReviewServingAdapterResult(
      kind: ReviewServingAdapterKind.fallback,
      selection: ServingSourceSelection(
        source: ReviewServingSourceKind.cloudReviewGroup,
        reason: 'p3_3_14_b_fallback_adapter_always_cloud',
        isFallbackToRetainedAnchor: true,
      ),
      additiveTag: '${kAdditiveTagPrefix}_fallback',
    );
  }

  /// Semantic boundary marker. Tests assert this contains 'additive_'.
  static const String kSemanticBoundary =
      'additive_adapter_family_all_paths_return_cloud_review_group_no_runtime_'
      'truth_switch_no_final_fact_owner_shift';

  /// Rollback target (locked, same as ReviewServingSeam).
  static const String kRollbackTarget =
      'cloud_review_group_current_runtime_path';
}
