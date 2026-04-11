import '../routing/session_entry_routing_compat.dart';

/// Shadow routing computation — never consumed by runtime.
///
/// routing_shadow_prep_v1 (FROZEN, P3.3.7)
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.7-002: routing shadow may only enter hidden marker / debug /
///                QA evidence layers. `study_default` remains the
///                runtime truth and MUST NOT be overridden.
/// RF-P3.3.7-006: shadow results must NEVER be visible to users.
///
/// ============================================================================
/// Purity & non-runtime guarantees
/// ============================================================================
///
/// - This runner is pure: no I/O, no side effects, no runtime mutation.
/// - The returned `RoutingShadowDecision` is EVIDENCE ONLY — it is
///   never consumed by home_page.dart, review_page.dart, or any CTA.
/// - Runtime `home_word_entry = study_default` continues to apply
///   regardless of what this runner computes.
/// - `wouldBeShown` is hard-coded to `false` on every decision so that
///   tests can lock in "this was never shown to a user".

/// A shadow routing decision. Always evidence-only.
class RoutingShadowDecision {
  /// Which routing candidate the shadow logic chose (see
  /// `RoutingCandidateType` in session_entry_routing_compat.dart).
  final RoutingCandidateType chosenCandidate;

  /// Human-readable explanation of why this candidate was chosen.
  /// Never surfaced to users.
  final String reason;

  /// Always `false` this round — shadow routing is never visible.
  /// Tests assert this is `false` to lock in the non-visibility.
  final bool wouldBeShown;

  const RoutingShadowDecision({
    required this.chosenCandidate,
    required this.reason,
    this.wouldBeShown = false,
  });
}

abstract final class RoutingShadowRunner {
  /// Compute what route WOULD be chosen if local-serving were active.
  ///
  /// Inputs:
  ///   - `hasActiveContinuation`: whether the current user has an
  ///     active review continuation block.
  ///   - `localDueCount`: how many cards are due locally per FSRS.
  ///   - `cloudReviewTarget`: how many reviews the cloud expects today.
  ///
  /// Returns a `RoutingShadowDecision`. This return value is NEVER
  /// consumed by any runtime routing code. `wouldBeShown` is always
  /// `false`. Runtime `home_word_entry = study_default` is preserved.
  ///
  /// Priority order:
  ///   1. active continuation → `continuationLocalCompatCandidate`
  ///   2. both local and cloud have review work → `plannerAwareEntryCandidate`
  ///   3. otherwise → `shadowRoutingCandidate` (default fallback)
  static RoutingShadowDecision computeShadowRoute({
    required bool hasActiveContinuation,
    required int localDueCount,
    required int cloudReviewTarget,
  }) {
    if (hasActiveContinuation) {
      return const RoutingShadowDecision(
        chosenCandidate:
            RoutingCandidateType.continuationLocalCompatCandidate,
        reason: 'active continuation detected (shadow-only)',
      );
    }

    if (localDueCount > 0 && cloudReviewTarget > 0) {
      return const RoutingShadowDecision(
        chosenCandidate: RoutingCandidateType.plannerAwareEntryCandidate,
        reason: 'both local and cloud have review work (shadow-only)',
      );
    }

    return const RoutingShadowDecision(
      chosenCandidate: RoutingCandidateType.shadowRoutingCandidate,
      reason: 'default shadow routing path (shadow-only)',
    );
  }
}
