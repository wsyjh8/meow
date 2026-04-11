import '../governance/shadow_parity_test_strategy.dart';

/// Parity comparison result + acceptance gate state types.
///
/// shadow_acceptance_gate_v1 (FROZEN, P3.3.7)
///
/// These types exist to carry shadow evidence between the parity checker
/// and the acceptance gate classifier. They are NEVER exposed to users.
/// RF-P3.3.7-001: shadow results can only enter evidence layers, not
/// become runtime facts.

/// Severity classification for a single parity comparison.
///
/// Maps to R3 rule IDs:
///   - `none`         → all checks pass
///   - `infoOnly`     → RF-P3.3.7-007 info-only mismatch (record only)
///   - `warning`      → RF-P3.3.7-008 warning mismatch (allow continuation)
///   - `mustHold`     → RF-P3.3.7-009 must-hold mismatch (immediately hold)
///   - `mustEscalate` → RF-P3.3.7-010 must-escalate (escalate to Room 1/2)
enum ParityMismatchSeverity {
  /// No mismatch — the two inputs align within acceptable tolerance.
  none,

  /// Info-only mismatch (RF-P3.3.7-007): affects only shadow interpretation
  /// details, NOT runtime truth or fact ingest. Action: record only.
  infoOnly,

  /// Warning mismatch (RF-P3.3.7-008): affects parity aesthetics or
  /// candidate consistency but NOT runtime truth. Action: allow
  /// continuation but record continuously.
  warning,

  /// Must-hold mismatch (RF-P3.3.7-009): any shadow result visible to
  /// users, local candidate affecting runtime, shadow modifying final
  /// facts, `review_group` wrongly marked exited, or `study_default`
  /// overridden by shadow. Action: immediately hold.
  mustHold,

  /// Must-escalate mismatch (RF-P3.3.7-010): requires DB schema, API
  /// core semantics, settlement owner changes, or cross-module contract
  /// changes. Action: escalate to Room 1 / Room 2.
  mustEscalate,
}

/// Single parity comparison result.
///
/// Produced by each `ParityChecker` comparison function. A batch of
/// these is passed to `ShadowAcceptanceGate.classify` to determine
/// the overall gate state.
class ParityComparisonResult {
  /// Which of the 5 parity check types this result came from.
  /// See `ParityCheckType` enum in
  /// `lib/core/governance/shadow_parity_test_strategy.dart`.
  final ParityCheckType checkType;

  /// Severity of any mismatch found.
  final ParityMismatchSeverity severity;

  /// Human-readable explanation of the result. Never shown to users.
  final String reason;

  /// Raw comparison details (counts, overlap ratios, etc.) for debug.
  final Map<String, Object?> details;

  const ParityComparisonResult({
    required this.checkType,
    required this.severity,
    required this.reason,
    this.details = const {},
  });

  /// True iff severity is `none` (full pass).
  bool get isPass => severity == ParityMismatchSeverity.none;

  /// True iff severity is `infoOnly` or `warning` — acceptable diffs.
  bool get isAcceptable =>
      severity == ParityMismatchSeverity.infoOnly ||
      severity == ParityMismatchSeverity.warning;

  /// True iff severity is `mustHold` — stop expanding scope.
  bool get isMustHold => severity == ParityMismatchSeverity.mustHold;

  /// True iff severity is `mustEscalate` — escalate to Room 1/2.
  bool get isMustEscalate => severity == ParityMismatchSeverity.mustEscalate;
}

/// The 4 states of the shadow acceptance gate (R4 plan §8).
///
/// These are the high-level classifications produced by
/// `ShadowAcceptanceGate.classify` given a batch of
/// `ParityComparisonResult`s.
///
///   - `parityPass`          — all conditions met, no leakage
///   - `acceptableMismatch`  — differences logged, runtime truth intact
///   - `mustHoldMismatch`    — stop expanding scope immediately
///   - `mustEscalate`        — escalate to Room 1 / Room 2
enum AcceptanceGateState {
  /// A. parity_pass (R4 §8.A, RF-P3.3.7-011)
  parityPass,

  /// B. acceptable_mismatch (R4 §8.B, RF-P3.3.7-012)
  acceptableMismatch,

  /// C. must_hold_mismatch (R4 §8.C, RF-P3.3.7-009)
  mustHoldMismatch,

  /// D. must_escalate (R4 §8.D, RF-P3.3.7-010)
  mustEscalate,
}
