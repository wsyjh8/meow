import 'package:flutter/foundation.dart';

import '../fact_settlement/fact_ingest_boundary_contract.dart';

/// Pure-local fact ingest shadow classifier.
///
/// fact_ingest_shadow_evidence_v1 (FROZEN, P3.3.7)
///
/// ============================================================================
/// Purpose
/// ============================================================================
///
/// Classifies a piece of local evidence as one of the three
/// `FactIngestAction` values (accept / reject / duplicate) to simulate
/// what the cloud fact layer WOULD return, WITHOUT actually hitting
/// the network.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.7-004: local fact ingest comparison only compares evidence
///                paths, not final truth ownership.
/// RF-P3.3.7-009: shadow must NEVER modify final fact / ledger /
///                daily_goal / streak.
///
/// ============================================================================
/// Classification rules (pure-local this round)
/// ============================================================================
///
///   1. If the idempotencyKey has been seen → `duplicate`
///   2. If wordId is empty OR rating invalid → `reject`
///   3. Otherwise → `accept` (and the idempotencyKey is added to the
///      seen-cache so a future call with the same key returns `duplicate`)
///
/// IMPORTANT:
///
/// - Real cloud fact-layer validation is DEFERRED to a future phase.
///   This round uses pure-local rules to produce evidence without
///   risking any runtime mutation.
/// - This classifier NEVER modifies ledger, daily_goal, streak, or
///   settlement. The classification result is evidence only.
/// - The classifier is stateful (holds a seen-keys set) so that
///   idempotency behavior can be tested end-to-end.
class FactIngestShadow {
  final Set<String> _seenIdempotencyKeys = <String>{};

  /// Classify a piece of evidence as one of the three
  /// `FactIngestAction` values.
  ///
  /// - Returns `duplicate` if `idempotencyKey` has been seen before.
  /// - Returns `reject` if `wordId` is empty or `rating` is invalid.
  /// - Returns `accept` otherwise, and records the idempotencyKey.
  FactIngestAction classifyEvidence({
    required String wordId,
    required String rating,
    required String idempotencyKey,
  }) {
    // Rule 1: duplicate takes priority over reject. This matches the
    // typical cloud idempotency-key semantics where a second submit of
    // the same key is dedup'd regardless of content.
    if (_seenIdempotencyKeys.contains(idempotencyKey)) {
      return FactIngestAction.duplicate;
    }

    // Rule 2: reject on invalid content.
    if (wordId.isEmpty || !_isValidRating(rating)) {
      return FactIngestAction.reject;
    }

    // Rule 3: accept — and remember the key for future dedup.
    _seenIdempotencyKeys.add(idempotencyKey);
    return FactIngestAction.accept;
  }

  /// Number of idempotency keys currently in the seen-cache.
  /// Used by tests to verify state transitions.
  @visibleForTesting
  int get seenKeyCount => _seenIdempotencyKeys.length;

  /// Reset the seen-keys cache. Only used by tests between cases.
  @visibleForTesting
  void reset() => _seenIdempotencyKeys.clear();

  /// Valid rating values accepted by this classifier.
  ///
  /// Intentionally includes both the ReviewPage binary form
  /// ('correct' / 'incorrect') and the StudyPage 4-button form
  /// ('again' / 'hard' / 'good' / 'easy') so the classifier can be
  /// used in both shadow contexts.
  static bool _isValidRating(String rating) =>
      const {'correct', 'incorrect', 'again', 'hard', 'good', 'easy'}
          .contains(rating);
}
