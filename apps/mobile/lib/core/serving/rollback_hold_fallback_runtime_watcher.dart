/// rollback_hold_fallback_runtime_watcher (P3.3.15 — first runtime consumer)
///
/// This is the S4 component of the P3.3.15 direct-cutover scaffolding.
/// It is the first file in the codebase that actually IMPORTS and USES
/// the `RollbackHoldFallbackState` enum defined in
/// `rollback_hold_fallback_orchestration.dart` (P3.3.14, Member 4).
/// Prior to this round the orchestration file was a pure contract
/// anchor with no runtime consumer.
///
/// The watcher is a pure function — it computes a state from inputs,
/// and the caller (ReviewPage) is responsible for acting on that state
/// (e.g. routing back to the cloud path on rollback).
///
/// ============================================================================
/// Scope this round
/// ============================================================================
///
/// The watcher is wired into `ReviewPage._loadReviewGroup()` but the
/// branching that would produce `localNonContinuation` selections is
/// gated behind `isReviewPageNonContinuationCutoverEnabled`, which is
/// false. So in production this round:
///
///   - The watcher is called exactly once per load attempt.
///   - Its input always corresponds to a cloud selection.
///   - Its output is always `normalServing` or `fallback`
///     (retained-anchor fallback under active continuation).
///   - No rollback transition fires in prod.
///
/// Tests exercise the rollback/local paths by injecting selections
/// that would only occur if the flag were flipped.
library;

import 'review_serving_seam.dart';
import 'rollback_hold_fallback_orchestration.dart';

/// Pure-function runtime watcher. No state, no side effects.
///
/// Decision table:
///
/// | Input                                             | Output        |
/// |---------------------------------------------------|---------------|
/// | localBuilderFailed = true                         | rollback      |
/// | backendSubmitFailed AND local selection           | rollback      |
/// | seam.isFallbackToRetainedAnchor = true            | fallback      |
/// | default (fresh cloud serving)                     | normalServing |
///
/// The `fallback` state covers any seam decision that fell back to
/// cloud under the retained-anchor posture — either because an active
/// continuation exists (designed anchor behavior), or because the
/// local path was flag-gated and not yet wired. Both cases are
/// semantically "cloud serving under retained-anchor posture" and
/// the observability layer needs to distinguish them from a fresh
/// cloud load.
abstract final class RollbackHoldFallbackRuntimeWatcher {
  /// Detect the current state given the seam selection + recent
  /// failure signals.
  ///
  /// [seamSelection] — the selection produced by
  /// `ReviewServingSeam.selectSource()`.
  ///
  /// [localBuilderFailed] — true when the most recent local-origin
  /// build attempt threw (any exception). Only meaningful when the
  /// selection was `localNonContinuation`.
  ///
  /// [backendSubmitFailed] — true when the most recent backend submit
  /// attempt failed. Only meaningful when the session's group ID was
  /// local-origin (which shouldn't happen — if it does, we rollback).
  static RollbackHoldFallbackState detect({
    required ServingSourceSelection seamSelection,
    bool localBuilderFailed = false,
    bool backendSubmitFailed = false,
  }) {
    // Rollback takes priority: any local-path failure means we go
    // back to the cloud path immediately.
    if (localBuilderFailed) {
      return RollbackHoldFallbackState.rollback;
    }
    if (backendSubmitFailed &&
        seamSelection.source == ReviewServingSourceKind.localNonContinuation) {
      return RollbackHoldFallbackState.rollback;
    }

    // Retained-anchor fallback — the seam chose cloud under a
    // retained-anchor posture (active continuation or local path
    // not yet wired). Both cases are the same from an observability
    // standpoint: cloud serving under the protective anchor layer.
    if (seamSelection.isFallbackToRetainedAnchor) {
      return RollbackHoldFallbackState.fallback;
    }

    return RollbackHoldFallbackState.normalServing;
  }

  /// Semantic boundary — this watcher observes, it does not advance
  /// runtime truth. Tests assert this contains
  /// `'watcher_observes_state_does_not_advance_runtime_truth'`.
  static const String kSemanticBoundary =
      'watcher_observes_state_does_not_advance_runtime_truth_and_cannot_'
      'elevate_any_candidate_layer_to_runtime_owner';
}
