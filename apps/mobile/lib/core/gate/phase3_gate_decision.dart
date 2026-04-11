/// phase3_gate_decision_v1 (FROZEN, P3.3.8)
///
/// 4-state gate classifier that decides whether Phase 3 can proceed to
/// the next layer of candidate review. NEVER outputs cutover-completion
/// strings — those are listed in
/// `Phase3GateForbiddenOutputs.kForbiddenDecisionOutputs` and tested
/// against.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.8-001: Gate only judges "can we enter the next layer candidate",
///                NOT "has cutover completed now".
/// RF-P3.3.8-002: Shadow evidence must satisfy explainable + repeatable
///                + within-bounds before gate can proceed.
/// RF-P3.3.8-003: "Looks more reasonable" alone is insufficient; evidence
///                must be stable, explainable, and boundary-safe.
///
/// ============================================================================
/// Priority order (most severe wins)
/// ============================================================================
///
///   escalate > hold > revise > proceed
///
/// - `escalate` dominates when any signal requires DB/API/contract
///   changes outside this round's scope.
/// - `hold` dominates when any runtime truth / fact boundary is at risk.
/// - `revise` applies when evidence exists but needs structural rework.
/// - `proceed` is reserved for the case where all 5 proceed conditions
///   are green AND no hold/escalate/revise signal fired.
library;

/// The 4 states of the Phase 3 gate decision.
///
/// None of these states represent cutover completion. The gate always
/// outputs one of these four — never a state like "cutover_completed".
enum Phase3GateDecision {
  /// A. proceed to next-layer candidate review.
  /// Requires all 5 proceed conditions to be green.
  proceedToNextLayerCandidateReview,

  /// B. hold — any hold trigger fired.
  /// Typical causes: shadow leakage, runtime truth at risk, overclaim.
  hold,

  /// C. revise — evidence is present but needs rework before decision.
  /// Typical causes: incomplete migration structure, unclear write-back
  /// order, source-neutral copy still has overclaim, candidate/current
  /// truth mixed in a helper.
  revise,

  /// D. escalate — requires Room 1 / Room 2 intervention.
  /// Typical causes: DB schema change needed, API core semantics change
  /// needed, reward/settlement owner shift needed, review_group needs
  /// early owner shift, user-visible cutover status needed.
  escalate,
}

/// Input struct for the gate classifier.
///
/// Each boolean represents a specific condition derived from the R2
/// tech note, R3 rules note, and R5 UI preflight. Tests populate these
/// to exercise the full decision matrix.
class Phase3GateEvidenceInputs {
  // ─── Proceed conditions (all must be true for proceed) ───
  final bool runtimeTruthGuardrailsGreen;
  final bool shadowEvidenceRepeatable;
  final bool candidateFramingWithinSeamBoundary;
  final bool reviewGroupExitStillGated;
  final bool writebackMigrationRollbackHoldPackReady;

  // ─── Hold triggers (any true → hold) ───
  final bool shadowResultLeakedToUsers;
  final bool reviewGroupWrittenAsExited;
  final bool localEvidenceChangedFinalFact;
  final bool studyDefaultChangedToAutoRouting;
  final bool helperSummaryOverclaim;

  // ─── Escalate triggers (any true → escalate, overrides hold) ───
  final bool needsDbSchemaChange;
  final bool needsApiCoreSemanticsChange;
  final bool needsRewardSettlementOwnerChange;
  final bool needsReviewGroupOwnerEarlyShift;
  final bool needsUserVisibleCutoverStatus;

  // ─── Revise triggers (any true → revise, if not escalate/hold) ───
  final bool migrationRollbackStructureIncomplete;
  final bool writebackOrderUnclear;
  final bool sourceNeutralCopyHasOverclaim;
  final bool candidateAndCurrentTruthMixed;
  final bool evidenceExistsButUnexplainable;

  const Phase3GateEvidenceInputs({
    this.runtimeTruthGuardrailsGreen = false,
    this.shadowEvidenceRepeatable = false,
    this.candidateFramingWithinSeamBoundary = false,
    this.reviewGroupExitStillGated = false,
    this.writebackMigrationRollbackHoldPackReady = false,
    this.shadowResultLeakedToUsers = false,
    this.reviewGroupWrittenAsExited = false,
    this.localEvidenceChangedFinalFact = false,
    this.studyDefaultChangedToAutoRouting = false,
    this.helperSummaryOverclaim = false,
    this.needsDbSchemaChange = false,
    this.needsApiCoreSemanticsChange = false,
    this.needsRewardSettlementOwnerChange = false,
    this.needsReviewGroupOwnerEarlyShift = false,
    this.needsUserVisibleCutoverStatus = false,
    this.migrationRollbackStructureIncomplete = false,
    this.writebackOrderUnclear = false,
    this.sourceNeutralCopyHasOverclaim = false,
    this.candidateAndCurrentTruthMixed = false,
    this.evidenceExistsButUnexplainable = false,
  });
}

/// Pure-function classifier for `Phase3GateDecision`.
///
/// No I/O, no mutation, no hidden state. Deterministic — the same
/// inputs always produce the same decision.
abstract final class Phase3GateClassifier {
  /// Classify evidence inputs into one of the 4 gate states.
  ///
  /// Priority order: escalate > hold > revise > proceed.
  /// The default when no signals fire and proceed conditions are not
  /// all green is `hold` (conservative).
  static Phase3GateDecision classify(Phase3GateEvidenceInputs inputs) {
    // Priority 1: escalate.
    if (inputs.needsDbSchemaChange ||
        inputs.needsApiCoreSemanticsChange ||
        inputs.needsRewardSettlementOwnerChange ||
        inputs.needsReviewGroupOwnerEarlyShift ||
        inputs.needsUserVisibleCutoverStatus) {
      return Phase3GateDecision.escalate;
    }

    // Priority 2: hold.
    if (inputs.shadowResultLeakedToUsers ||
        inputs.reviewGroupWrittenAsExited ||
        inputs.localEvidenceChangedFinalFact ||
        inputs.studyDefaultChangedToAutoRouting ||
        inputs.helperSummaryOverclaim) {
      return Phase3GateDecision.hold;
    }

    // Priority 3: revise.
    if (inputs.migrationRollbackStructureIncomplete ||
        inputs.writebackOrderUnclear ||
        inputs.sourceNeutralCopyHasOverclaim ||
        inputs.candidateAndCurrentTruthMixed ||
        inputs.evidenceExistsButUnexplainable) {
      return Phase3GateDecision.revise;
    }

    // Priority 4: proceed (all 5 conditions must be green).
    if (inputs.runtimeTruthGuardrailsGreen &&
        inputs.shadowEvidenceRepeatable &&
        inputs.candidateFramingWithinSeamBoundary &&
        inputs.reviewGroupExitStillGated &&
        inputs.writebackMigrationRollbackHoldPackReady) {
      return Phase3GateDecision.proceedToNextLayerCandidateReview;
    }

    // Default: hold (conservative).
    return Phase3GateDecision.hold;
  }
}

/// Strings that must NEVER be output by this gate.
///
/// The gate is explicitly NOT a cutover-completion checker. Any future
/// extension that adds a cutover-completion state would cross an
/// escalation boundary and require a Room 1 pin.
abstract final class Phase3GateForbiddenOutputs {
  /// Canonical forbidden decision output strings.
  /// Tests assert none of these appear as `Phase3GateDecision` values.
  static const List<String> kForbiddenDecisionOutputs = [
    'runtime_owner_shift_completed',
    'local_serving_cutover_completed',
    'review_group_exited',
    'unified_planner_established',
  ];
}
