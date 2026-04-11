import '../memory/card_state_data.dart';
import '../review/review_group_compatibility.dart';
import '../serving/local_serving_candidate_contract.dart';
import 'local_serving_candidate.dart';

/// Builds local shadow candidates from FSRS inputs.
///
/// local_serving_shadow_run_v1 (FROZEN, P3.3.7)
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.7-002: shadow run candidates enter limited execution ONLY in
///                dev/flag/QA evidence layers — NEVER in user-visible
///                runtime paths.
/// RF-P3.3.7-005: shadow results allowed visible only to dev/test/
///                internal debug/QA/governance documents.
///
/// ============================================================================
/// Purity & non-runtime guarantees
/// ============================================================================
///
/// - These functions are pure: no I/O, no DB reads/writes, no network.
/// - Callers (tests only) pass in `CardStateData` lists and receive
///   `LocalServingCandidate` objects.
/// - Every candidate produced has `shadowOnly = true` and
///   `servingEligibilityState = ServingEligibilityState.shadowOnly`.
/// - Runtime code MUST NEVER call these functions. Feature-flag gating
///   via `P3FeatureGuard.isLocalServingShadowRunEnabled` is FALSE this
///   round; tests bypass the flag by calling directly.

abstract final class LocalServingShadowRunner {
  /// Build a local_due_queue_candidate from a list of due CardStateData.
  ///
  /// Source: FSRS scheduler due list (typically obtained via
  /// `FsrsService.listDueCards`).
  ///
  /// - `dueCards`: candidate due cards, already sorted by due ASC by caller.
  /// - `nowUtc`: timestamp stamped onto the candidate.
  /// - `limit`: optional maximum item count. If provided and smaller
  ///   than `dueCards.length`, the returned candidate is truncated.
  ///
  /// Returns a `LocalServingCandidate` with:
  ///   - sourceType = localDueShadow
  ///   - shadowOnly = true (hard-coded)
  ///   - ownerLayer = planning (future direction)
  ///   - servingEligibilityState = shadowOnly
  ///   - candidateReason = fsrsComputed
  static LocalServingCandidate buildLocalDueQueueCandidate({
    required List<CardStateData> dueCards,
    required DateTime nowUtc,
    int? limit,
  }) {
    final truncated = limit != null && dueCards.length > limit
        ? dueCards.take(limit).toList()
        : dueCards;

    final wordIds = truncated.map((c) => c.wordId).toList(growable: false);

    return LocalServingCandidate(
      sourceType: LocalServingSourceType.localDueShadow,
      sourceId: 'local_due_shadow_${nowUtc.millisecondsSinceEpoch}',
      ownerLayer: PlannerOwnerLayer.planning,
      shadowOnly: true,
      candidateReason: CandidateReason.fsrsComputed,
      generatedAtUtc: nowUtc,
      itemCount: wordIds.length,
      servingEligibilityState: ServingEligibilityState.shadowOnly,
      wordIds: wordIds,
    );
  }

  /// Build a local_generated_review_session_candidate from FSRS inputs.
  ///
  /// Interleaves due cards + hypothetical new cards, respecting the
  /// daily new card limit. The output is SHADOW-ONLY — it is never
  /// consumed by StudyPage, ReviewPage, or SessionBuilder in runtime.
  ///
  /// - `dueCards`: currently-due cards from FSRS.
  /// - `newCardsToday`: how many new cards were already introduced today.
  /// - `newCardsDailyLimit`: user's max new cards per day.
  /// - `nowUtc`: timestamp stamped onto the candidate.
  /// - `sessionId`: caller-provided ID for traceability.
  ///
  /// Returns a `LocalServingCandidate` with:
  ///   - sourceType = localGeneratedShadow
  ///   - shadowOnly = true (hard-coded)
  ///   - ownerLayer = planning
  ///   - servingEligibilityState = shadowOnly
  ///   - candidateReason = localGenerated
  ///   - itemCount reflects due-interleaved packaging
  static LocalServingCandidate buildLocalGeneratedSessionCandidate({
    required List<CardStateData> dueCards,
    required int newCardsToday,
    required int newCardsDailyLimit,
    required DateTime nowUtc,
    required String sessionId,
  }) {
    final remainingNewSlots = newCardsDailyLimit - newCardsToday;
    final newSlots = remainingNewSlots > 0 ? remainingNewSlots : 0;

    // Shadow packaging: dueCards form the review portion; we append a
    // placeholder representation of new-card slots by word_id. Since
    // real new-word selection requires cached_words lookup (an I/O op),
    // this shadow runner uses synthetic placeholder IDs for new slots.
    // This is acceptable because the runner is evidence-only and the
    // parity checker compares the REVIEW portion against cloud.
    final reviewWordIds =
        dueCards.map((c) => c.wordId).toList(growable: false);

    // Interleave: we keep due cards first in shadow, then synthetic
    // new slots. Real SessionBuilder uses 3:1 ratio, but parity checks
    // this round only examine due-portion overlap.
    final allIds = <String>[
      ...reviewWordIds,
      for (var i = 0; i < newSlots; i++) 'shadow_new_slot_$i',
    ];

    return LocalServingCandidate(
      sourceType: LocalServingSourceType.localGeneratedShadow,
      sourceId: sessionId,
      ownerLayer: PlannerOwnerLayer.planning,
      shadowOnly: true,
      candidateReason: CandidateReason.localGenerated,
      generatedAtUtc: nowUtc,
      itemCount: allIds.length,
      servingEligibilityState: ServingEligibilityState.shadowOnly,
      wordIds: allIds,
    );
  }
}
