import '../governance/shadow_parity_test_strategy.dart';
import 'parity_result.dart';

/// Shadow acceptance gate classifier.
///
/// shadow_acceptance_gate_v1 (FROZEN, P3.3.7)
///
/// ============================================================================
/// Purpose
/// ============================================================================
///
/// Classifies a batch of `ParityComparisonResult`s into one of the 4
/// `AcceptanceGateState` values defined by R4 plan §8:
///
///   A. `parityPass`          — all checks pass, no leakage
///   B. `acceptableMismatch`  — minor differences, runtime truth intact
///   C. `mustHoldMismatch`    — stop expanding scope immediately
///   D. `mustEscalate`        — escalate to Room 1 / Room 2
///
/// ============================================================================
/// Priority order
/// ============================================================================
///
/// `mustEscalate` > `mustHold` > any mismatch → `acceptable` > `parityPass`
///
/// A single `mustEscalate` result dominates the whole batch. If no
/// `mustEscalate` is present but any `mustHold` is, the batch is
/// `mustHoldMismatch`. If no severe results are present but any
/// comparison has a non-zero severity, the batch is `acceptableMismatch`.
/// Only when every result is `none` does the batch count as `parityPass`.
///
/// ============================================================================
/// Phase 3 readiness
/// ============================================================================
///
/// `hasMinimumPhase3Evidence` answers one of the R4 §9 questions:
/// "did the shadow run produce a stable evidence set?" It returns true
/// only when:
///   1. The batch classifies as `parityPass` or `acceptableMismatch`
///      (NOT `mustHold` or `mustEscalate`), AND
///   2. Every `ParityCheckType` appears at least once in the batch.
///
/// Neither condition alone is sufficient. Both are needed to satisfy
/// R4 §9 minimum evidence requirements. A true return does NOT mean
/// Phase 3 cutover is authorized — it means the Phase 2 evidence
/// collection is complete.

abstract final class ShadowAcceptanceGate {
  /// Classify a batch of parity comparison results into one of the 4
  /// `AcceptanceGateState` values.
  ///
  /// Returns the most severe state found in the batch.
  /// An empty input list returns `parityPass` (nothing to object to).
  static AcceptanceGateState classify(List<ParityComparisonResult> results) {
    // Priority 1: must_escalate dominates.
    if (results.any((r) => r.isMustEscalate)) {
      return AcceptanceGateState.mustEscalate;
    }
    // Priority 2: must_hold.
    if (results.any((r) => r.isMustHold)) {
      return AcceptanceGateState.mustHoldMismatch;
    }
    // Priority 3: all pass.
    if (results.isEmpty || results.every((r) => r.isPass)) {
      return AcceptanceGateState.parityPass;
    }
    // Default: acceptable mismatch.
    return AcceptanceGateState.acceptableMismatch;
  }

  /// Check whether the batch has minimum Phase 3 readiness evidence.
  ///
  /// Returns true iff:
  ///   1. `classify(results)` is `parityPass` or `acceptableMismatch`.
  ///   2. All 5 `ParityCheckType` values appear at least once.
  ///
  /// This does NOT grant Phase 3 cutover permission — it only says
  /// "the Phase 2 evidence collection produced the minimum set".
  static bool hasMinimumPhase3Evidence(
      List<ParityComparisonResult> results) {
    final state = classify(results);
    if (state == AcceptanceGateState.mustHoldMismatch ||
        state == AcceptanceGateState.mustEscalate) {
      return false;
    }

    final presentCheckTypes = results.map((r) => r.checkType).toSet();
    return presentCheckTypes.length == ParityCheckType.values.length;
  }
}
