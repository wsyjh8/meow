import '../api/api_client.dart';
import '../fact_settlement/fact_ingest_boundary_contract.dart';
import '../governance/shadow_parity_test_strategy.dart';
import 'local_serving_candidate.dart';
import 'parity_result.dart';

/// Real parity check comparison logic.
///
/// parity_checks_v1 (FROZEN, P3.3.7)
///
/// One function per `ParityCheckType` (5 total):
///   1. queueCandidateSize
///   2. itemIdentityOverlap
///   3. continuationEligibility
///   4. submitAfterEffects
///   5. factIngestBehavior
///
/// ============================================================================
/// Purity & evidence-only guarantees
/// ============================================================================
///
/// All functions are pure: they do not mutate inputs, do not hit the
/// network, and do not write any runtime state. Results are EVIDENCE
/// ONLY — never promoted to runtime truth (RF-P3.3.7-001).
///
/// Severity classification is conservative: if any check finds that
/// the shadow and runtime would disagree in a way that affects user
/// experience, the result is `warning` at most. Only cases that would
/// REQUIRE changing runtime truth or contract are `mustHold`/`mustEscalate`,
/// but those are never triggered by pure comparison — they can only be
/// triggered by external signals (e.g., runtime leakage detected).

abstract final class ParityChecker {
  /// Compare queue sizes between local shadow candidate and cloud
  /// `review_group`.
  ///
  /// Tolerance:
  ///   - exact match        → pass (severity none)
  ///   - ±20% difference    → infoOnly
  ///   - >20% difference    → warning
  ///   - one side empty     → warning (may indicate timing gap)
  static ParityComparisonResult compareQueueSize({
    required LocalServingCandidate local,
    required ReviewGroup cloud,
  }) {
    final localCount = local.itemCount;
    final cloudCount = cloud.items.length;

    // Both empty
    if (localCount == 0 && cloudCount == 0) {
      return const ParityComparisonResult(
        checkType: ParityCheckType.queueCandidateSize,
        severity: ParityMismatchSeverity.none,
        reason: 'both queues empty',
        details: {'localCount': 0, 'cloudCount': 0},
      );
    }

    // One side empty
    if (localCount == 0 || cloudCount == 0) {
      return ParityComparisonResult(
        checkType: ParityCheckType.queueCandidateSize,
        severity: ParityMismatchSeverity.warning,
        reason:
            'one side empty: local=$localCount, cloud=$cloudCount (timing gap)',
        details: {'localCount': localCount, 'cloudCount': cloudCount},
      );
    }

    // Both non-empty
    if (localCount == cloudCount) {
      return ParityComparisonResult(
        checkType: ParityCheckType.queueCandidateSize,
        severity: ParityMismatchSeverity.none,
        reason: 'sizes match exactly: $localCount',
        details: {'localCount': localCount, 'cloudCount': cloudCount},
      );
    }

    final diff = (localCount - cloudCount).abs();
    final reference = cloudCount > localCount ? cloudCount : localCount;
    final pct = diff / reference;

    if (pct <= 0.2) {
      return ParityComparisonResult(
        checkType: ParityCheckType.queueCandidateSize,
        severity: ParityMismatchSeverity.infoOnly,
        reason:
            'sizes within 20% tolerance: local=$localCount, cloud=$cloudCount',
        details: {
          'localCount': localCount,
          'cloudCount': cloudCount,
          'percentDiff': pct,
        },
      );
    }

    return ParityComparisonResult(
      checkType: ParityCheckType.queueCandidateSize,
      severity: ParityMismatchSeverity.warning,
      reason:
          'sizes diverge beyond 20%: local=$localCount, cloud=$cloudCount',
      details: {
        'localCount': localCount,
        'cloudCount': cloudCount,
        'percentDiff': pct,
      },
    );
  }

  /// Compare word_id overlap between local shadow candidate and cloud
  /// `review_group`.
  ///
  /// Computes Jaccard-style overlap: |intersection| / |union|.
  ///
  /// Thresholds:
  ///   - overlap ≥ 70%      → pass (severity none)
  ///   - 40% ≤ overlap < 70% → infoOnly
  ///   - overlap < 40%       → warning
  static ParityComparisonResult compareItemIdentityOverlap({
    required LocalServingCandidate local,
    required ReviewGroup cloud,
  }) {
    final localSet = local.wordIds.toSet();
    final cloudSet = cloud.items.map((i) => i.wordId).toSet();

    if (localSet.isEmpty && cloudSet.isEmpty) {
      return const ParityComparisonResult(
        checkType: ParityCheckType.itemIdentityOverlap,
        severity: ParityMismatchSeverity.none,
        reason: 'both word sets empty',
        details: {'overlap': 1.0},
      );
    }

    final intersection = localSet.intersection(cloudSet);
    final union = localSet.union(cloudSet);
    final overlap = union.isEmpty ? 0.0 : intersection.length / union.length;

    if (overlap >= 0.7) {
      return ParityComparisonResult(
        checkType: ParityCheckType.itemIdentityOverlap,
        severity: ParityMismatchSeverity.none,
        reason: 'overlap ≥ 70%: ${(overlap * 100).toStringAsFixed(1)}%',
        details: {
          'overlap': overlap,
          'intersectionCount': intersection.length,
          'unionCount': union.length,
        },
      );
    }

    if (overlap >= 0.4) {
      return ParityComparisonResult(
        checkType: ParityCheckType.itemIdentityOverlap,
        severity: ParityMismatchSeverity.infoOnly,
        reason:
            'overlap 40-70%: ${(overlap * 100).toStringAsFixed(1)}% (info)',
        details: {
          'overlap': overlap,
          'intersectionCount': intersection.length,
          'unionCount': union.length,
        },
      );
    }

    return ParityComparisonResult(
      checkType: ParityCheckType.itemIdentityOverlap,
      severity: ParityMismatchSeverity.warning,
      reason:
          'overlap < 40%: ${(overlap * 100).toStringAsFixed(1)}% (diverged)',
      details: {
        'overlap': overlap,
        'intersectionCount': intersection.length,
        'unionCount': union.length,
      },
    );
  }

  /// Compare continuation eligibility decisions.
  ///
  /// - Both say "continue" or both say "complete" → pass
  /// - One says "continue" and the other says "complete" → warning
  static ParityComparisonResult compareContinuationEligibility({
    required bool localWouldContinue,
    required bool cloudContinues,
  }) {
    if (localWouldContinue == cloudContinues) {
      return ParityComparisonResult(
        checkType: ParityCheckType.continuationEligibility,
        severity: ParityMismatchSeverity.none,
        reason:
            'both agree on continuation: $localWouldContinue',
        details: {
          'localWouldContinue': localWouldContinue,
          'cloudContinues': cloudContinues,
        },
      );
    }

    return ParityComparisonResult(
      checkType: ParityCheckType.continuationEligibility,
      severity: ParityMismatchSeverity.warning,
      reason:
          'continuation mismatch: local=$localWouldContinue, cloud=$cloudContinues',
      details: {
        'localWouldContinue': localWouldContinue,
        'cloudContinues': cloudContinues,
      },
    );
  }

  /// Compare submit after-effects evidence completeness.
  ///
  /// - All `requiredFields` present in `localEvidence` → pass
  /// - Any required field missing → warning
  static ParityComparisonResult compareSubmitAfterEffects({
    required Map<String, Object?> localEvidence,
    required Set<String> requiredFields,
  }) {
    final missing = requiredFields
        .where((f) => !localEvidence.containsKey(f) || localEvidence[f] == null)
        .toList();

    if (missing.isEmpty) {
      return ParityComparisonResult(
        checkType: ParityCheckType.submitAfterEffects,
        severity: ParityMismatchSeverity.none,
        reason: 'all required evidence fields present',
        details: {
          'requiredFieldCount': requiredFields.length,
          'presentFieldCount': requiredFields.length,
        },
      );
    }

    return ParityComparisonResult(
      checkType: ParityCheckType.submitAfterEffects,
      severity: ParityMismatchSeverity.warning,
      reason: 'missing ${missing.length} required evidence field(s)',
      details: {
        'missingFields': missing,
        'requiredFieldCount': requiredFields.length,
      },
    );
  }

  /// Compare ingest behavior classification.
  ///
  /// Checks whether the local shadow classifier agrees with an expected
  /// cloud response (provided by the test — no network calls).
  ///
  /// - Same `FactIngestAction` → pass
  /// - Different `FactIngestAction` → warning
  static ParityComparisonResult compareIngestBehavior({
    required FactIngestAction localClassification,
    required FactIngestAction expectedClassification,
  }) {
    if (localClassification == expectedClassification) {
      return ParityComparisonResult(
        checkType: ParityCheckType.factIngestBehavior,
        severity: ParityMismatchSeverity.none,
        reason:
            'local and expected agree: ${localClassification.name}',
        details: {
          'local': localClassification.name,
          'expected': expectedClassification.name,
        },
      );
    }

    return ParityComparisonResult(
      checkType: ParityCheckType.factIngestBehavior,
      severity: ParityMismatchSeverity.warning,
      reason:
          'ingest behavior diverged: local=${localClassification.name}, '
          'expected=${expectedClassification.name}',
      details: {
        'local': localClassification.name,
        'expected': expectedClassification.name,
      },
    );
  }
}
