/// round_gates_and_guardrails.dart (MERGED in P3.3.14 consolidation round)
///
/// Consolidated round-level gates / locks / runtime-truth boundaries / narrowing guardrails / cleanup gates from P3.3.8 through P3.3.14. Covers phase3 gate classifier (P3.3.8), runtime-truth switch boundary (P3.3.9), retained-anchor narrowing (P3.3.11), true-exit-candidate narrowing (P3.3.13), final-cutover judgment lock (P3.3.14), same-round cleanup gate (P3.3.14).
///
/// This file was consolidated from 6 original per-round files to
/// reduce gate-file sprawl. Class names and constants are preserved
/// exactly so all existing tests continue to work after updating
/// their import paths.
library;

// ============================================================================
// Merged from: phase3_gate_decision.dart
// ============================================================================
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

// ============================================================================
// Merged from: runtime_truth_switch_boundary.dart
// ============================================================================
/// runtime_truth_switch_boundary_v1 (FROZEN, P3.3.9)
///
/// Contract anchor listing the single runtime truth allowed to switch
/// and all runtime truths that MUST remain unchanged this round.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.9-005: following runtime truths must remain unchanged:
///                - home page continues study_default
///                - active continuation independent without silent reroute
///                - review_group continues as current runtime serving owner
///                - final fact/settlement via backend
///                - preview/explanation cannot become committed plan fact
///
/// RF-P3.3.9-006: even if ReviewPage serving seam switches narrowly,
///                must not alter home page summary truth, active
///                continuation high-priority semantics, group completion/
///                settlement truth, reward/daily goal/streak/learning day
///                result expression.

abstract final class RuntimeTruthSwitchBoundary {
  /// The ONLY runtime truth allowed to switch this round.
  /// Tests assert this exact string.
  static const String kOnlyAllowedSwitch = 'review_queue_serving_source';

  /// Runtime truths that MUST remain unchanged.
  /// Tests assert all canonical unchanged truths are present.
  static const List<String> kMustRemainUnchanged = [
    'home_page_home_word_entry_study_default',
    'active_continuation_independent_intake',
    'review_group_current_runtime_serving_owner_main_path_fact',
    'review_summary_completion_settlement_final_fact',
    'reward_ledger_daily_goal_streak_learning_day_final_fact',
    'user_visible_owner_shift_local_serving_enabled_cutover_completed_mode_declaration',
  ];

  /// Switches forbidden this round.
  /// Tests assert all canonical forbidden switches are present.
  static const List<String> kForbiddenSwitches = [
    'home_page_route_switch',
    'active_continuation_source_switch',
    'final_fact_owner_shift',
    'reward_settlement_owner_shift',
    'daily_goal_owner_shift',
    'streak_learning_day_owner_shift',
    'preview_explanation_contract_shift',
  ];

  /// Eligibility requirements before the allowed switch can return
  /// `localNonContinuation`. All must hold.
  /// Tests assert all 4 canonical requirements are present.
  static const List<String> kEligibilityRequirements = [
    'only_in_reviewpage',
    'only_non_continuation_path',
    'only_when_local_serving_candidate_readiness_met',
    'only_when_fallback_rollback_holdnote_observability_all_present',
  ];
}

// ============================================================================
// Merged from: retained_anchor_narrowing_guardrail.dart
// ============================================================================
/// retained_anchor_narrowing_guardrail_v1 (FROZEN, P3.3.11)
///
/// Explicit narrowing rules: what CAN be very-narrowly narrowed vs what
/// CANNOT be narrowed. This contract complements P3.3.10's
/// `retained_anchor_to_exit_transition_v1` with more granular execution-
/// ready guardrails.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.11-007: only 5 items may narrow very narrowly; rollback target,
///                 active continuation, completion gating, settlement
///                 trigger, non-cutover baseline remain forbidden.
/// RF-P3.3.11-015: only very-narrow narrowing ranges allowed.
///
/// ============================================================================
/// Canonical rule
/// ============================================================================
///
/// Explanation layer and helper scope MAY narrow.
/// Owner identity, rollback target, completion gating, settlement
/// trigger CANNOT narrow.

abstract final class RetainedAnchorNarrowingGuardrail {
  /// The 5 items that CAN be very-narrowly narrowed this round.
  /// Tests assert length == 5 and all canonical items present.
  static const List<String> kCanNarrowVeryNarrowly = [
    'source_neutral_helper_summary_group_only_wording_coupling',
    'first_page_review_helper_empty_state_no_review_state_retained_anchor_aware_rewrite',
    'rollback_fallback_explanation_historical_redundancy_removal',
    'marker_posture_documentation_ui_docs_expression_layer_optimization',
    'future_narrowable_rollback_bucket_judgment_assessment',
  ];

  /// The 7 items that CANNOT be narrowed (immobile).
  /// Tests assert length == 7 and all canonical items present.
  static const List<String> kCannotNarrow = [
    'rollback_target_cloud_review_group_current_runtime_path',
    'current_runtime_serving_owner_identity',
    'active_continuation_identity',
    'current_completion_gating',
    'current_settlement_trigger',
    'compatibility_anchor',
    'non_cutover_baseline_path',
  ];

  /// Stop conditions that MUST trigger hold/rollback/escalate.
  /// Tests assert length == 7 and all canonical triggers present.
  static const List<String> kStopConditions = [
    'active_continuation_mistakenly_cut_to_local_path',
    'local_subset_written_as_current_reviewpage_full_truth',
    'local_evidence_directly_changes_final_ledger_daily_goal_streak_settlement',
    'home_page_route_changed_to_planner_aware_auto_routing',
    'user_visible_cutover_owner_shift_exit_uplift_overclaim',
    'db_schema_api_core_semantics_change_required',
    'rollback_path_nonexistent_unverifiable_unexplainable',
  ];

  /// Semantic boundary: explanation layer / helper scope narrowable;
  /// owner identity / rollback target / completion gating / settlement
  /// trigger immobile.
  static const String kSemanticBoundary =
      'explanation_layer_helper_scope_may_narrow_owner_identity_rollback_target_completion_gating_settlement_trigger_cannot';
}

// ============================================================================
// Merged from: true_exit_candidate_narrowing_guardrail.dart
// ============================================================================
/// true_exit_candidate_narrowing_guardrail_v1 (FROZEN, P3.3.13)
///
/// NEW guardrail this round. Defines what retained-anchor-dependent
/// wording / helper scope / QA & docs narrative MAY be very-narrowly
/// narrowed vs what MUST remain immobile while `review_group` is at
/// the true-exit-candidate level. Complements P3.3.11's
/// `retained_anchor_narrowing_guardrail_v1` and P3.3.12's
/// `exit_candidate_to_true_exit_transition_v1` but applies to the
/// true-exit-candidate layer specifically.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.13-017: rollback target stays fixed to
///                 `cloud_review_group_current_runtime_path`.
/// RF-P3.3.13-018: only very-narrow narrowing of dependency-expression
///                 layer allowed (5 items listed); bone-structure
///                 anchors remain fixed (6 items listed).
/// RF-P3.3.13-019: 7 must-hold / must-escalate stop-conditions —
///                 any one of them triggers immediate hold / rollback /
///                 escalate.
///
/// ============================================================================
/// Canonical rule
/// ============================================================================
///
///   Very-narrow narrowing is permitted ONLY on the dependency-
///   expression layer. Bone-structure anchors (rollback target, owner
///   identity, retained anchor identity, active continuation,
///   completion/settlement explanation pathway, compatibility anchor /
///   QA baseline reference) remain fully fixed.

abstract final class TrueExitCandidateNarrowingGuardrail {
  /// Canonical rule. Tests assert this contains
  /// 'very_narrow_narrowing_only_on_dependency_expression'.
  static const String kCanonicalRule =
      'very_narrow_narrowing_only_on_dependency_expression_bone_structure_anchors_remain_fixed';

  /// The 5 items that CAN be very-narrowly narrowed this round
  /// (RF-P3.3.13-018). Tests assert length == 5 and all canonical
  /// items present.
  static const List<String> kCanNarrowVeryNarrowly = [
    'group_only_wording_dependency_scope_narrowing',
    'source_neutral_helper_summary_empty_state_group_only_wording_dependency',
    'retained_anchor_aware_fallback_copy_coverage_scope_optimization',
    'qa_docs_judgment_about_ui_assets_no_longer_must_group_only',
    'rollback_fallback_explanation_redundant_wording_historical_cleanup',
  ];

  /// The 6 bone-structure anchors that CANNOT be narrowed this round
  /// (immobile). Tests assert length == 6 and all canonical items
  /// present.
  static const List<String> kCannotNarrow = [
    'rollback_target_cloud_review_group_current_runtime_path',
    'current_visible_owner_identity',
    'retained_fallback_anchor_identity',
    'active_continuation_current_acceptance_path',
    'current_completion_gating_settlement_trigger_explanation_pathway',
    'compatibility_anchor_qa_baseline_reference',
  ];

  /// 7 stop-conditions (RF-P3.3.13-019). Any one of them triggers
  /// immediate hold / rollback / escalate. Tests assert length == 7
  /// and all canonical triggers present.
  static const List<String> kStopConditions = [
    'home_page_study_default_touched',
    'active_continuation_silent_reroute',
    'review_group_written_as_true_exit_or_cleanable_or_fallback_only',
    'local_stronger_path_affects_final_fact_or_settlement_truth',
    'user_visible_switched_to_local_planning_or_main_chain_live_or_cutover_or_uplift_completed',
    'execution_subset_or_candidate_or_readiness_written_as_runtime_truth',
    'db_schema_or_api_core_semantics_rewrite_required_to_proceed',
  ];

  /// Semantic boundary: the dependency-expression layer is narrowable;
  /// bone-structure anchors remain immobile.
  static const String kSemanticBoundary =
      'dependency_expression_layer_narrowable_bone_structure_anchors_remain_immobile';
}

// ============================================================================
// Merged from: final_cutover_judgment_lock.dart
// ============================================================================
/// final_cutover_judgment_lock_v1 (FROZEN, P3.3.14)
///
/// A-checkpoint master lock for P3.3.14 — Final Cutover Program Round.
///
/// This is the master judgment lock for the round. It pins the 6 groups
/// of hard preconditions that MUST continue to hold through A → B → C,
/// the 6 still-dependent paths that cannot be silently rerouted, and
/// the A-checkpoint pass-gate conditions that Room 4 must satisfy
/// before Room 1 may authorize B execution.
///
/// The lock is a JUDGMENT level contract — it pins what is locked in
/// place this round, not what has been switched. It explicitly does
/// NOT assert that runtime truth has advanced.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.14-001: A checkpoint preconditions — 6 groups of hard
///                 preconditions must be written into code as gate /
///                 guard / assert / flag / contract assets.
/// RF-P3.3.14-002: still-dependent paths inventory — 6 paths continue
///                 to depend on cloud `review_group` this round and
///                 must be listed explicitly.
/// RF-P3.3.14-003: A checkpoint overclaim prohibitions — Room 4 may
///                 not express any of the 32 user-visible forbidden
///                 claims via code, copy, or test surface.
/// RF-P3.3.14-004: A checkpoint pass gate — all preconditions written
///                 hard + still-dependent paths listed + overclaim
///                 guardrails in place + no must-hold mismatch.

/// The 6 groups of A checkpoint hard preconditions.
enum FinalCutoverJudgmentLockGroup {
  /// Group 1: Runtime truth immovables —
  /// home_word_entry = study_default; ReviewPage current serving owner
  /// remains cloud `review_group`; active continuation path not
  /// silently rerouted; final fact / settlement owner does not shift
  /// alongside serving seam advancement.
  runtimeTruthImmovables,

  /// Group 2: Rollback immovables — rollback target remains locked at
  /// `cloud_review_group_current_runtime_path`; hold fallback must
  /// return stably to cloud current runtime path; rollback / hold copy
  /// must NOT be written as historical-only.
  rollbackImmovables,

  /// Group 3: True-exit preconditions inventory — still-dependent paths
  /// listed, still-missing preconditions listed, and the strict layer
  /// separation (`true-exit-candidate ≠ true-exit-started ≠
  /// true-exit-absorbed`) must remain visible in code.
  trueExitPreconditionsInventory,

  /// Group 4: DB/API uplift absorb inventory — seam families must be
  /// split into absorbed-gate-ready vs marker-only; DB schema rewrite
  /// and API core semantics rewrite remain out of scope; active
  /// baseline remains `DB/API v0.2.1`.
  dbApiUpliftAbsorbInventory,

  /// Group 5: Fact-owner guardrail — serving seam advancement MUST
  /// NOT automatically bring review fact / daily completion /
  /// settlement / streak / learning_day / reward ledger owner shift;
  /// stronger-ingest path only enters candidate / readiness /
  /// absorbed-judgment discussion, never direct final-owner promotion.
  factOwnerGuardrail,

  /// Group 6: Cleanup gating — old-path purge, historical demotion,
  /// deprecated candidate cleanup, runtime truth upgrade are ALL
  /// postponed to C; A must NOT proactively consume cleanup.
  cleanupGating,
}

abstract final class FinalCutoverJudgmentLock {
  /// Current stage marker — round P3.3.14, A-checkpoint judgment lock.
  /// Tests assert this exact string.
  static const String kStatus =
      'p3_3_14_a_checkpoint_final_judgment_lock_pinned_not_runtime_truth_advanced';

  /// The 6 groups of A-checkpoint hard preconditions.
  /// Tests assert length == 6.
  static const List<String> kSixHardPreconditionGroups = [
    'runtime_truth_immovables',
    'rollback_immovables',
    'true_exit_preconditions_inventory',
    'db_api_uplift_absorb_inventory',
    'fact_owner_guardrail',
    'cleanup_gating',
  ];

  /// The 4 runtime-truth immovables (group 1).
  /// Tests assert length == 4.
  static const List<String> kRuntimeTruthImmovables = [
    'home_word_entry_remains_study_default',
    'review_page_current_visible_serving_owner_remains_cloud_review_group',
    'active_continuation_current_acceptance_path_must_not_be_silently_rewritten',
    'final_fact_and_settlement_owner_does_not_shift_with_serving_seam_advancement',
  ];

  /// The 3 rollback immovables (group 2).
  /// Tests assert length == 3.
  static const List<String> kRollbackImmovables = [
    'rollback_target_remains_cloud_review_group_current_runtime_path',
    'hold_fallback_must_return_stably_to_cloud_current_runtime_path',
    'rollback_and_hold_copy_must_not_be_written_as_historical_only',
  ];

  /// The canonical rollback target string for this round.
  /// Tests assert exact equality. Matches ReviewServingSeam.kRollbackTarget.
  static const String kCanonicalRollbackTarget =
      'cloud_review_group_current_runtime_path';

  /// The 6 still-dependent paths that continue to require cloud
  /// `review_group` this round (RF-P3.3.14-002).
  /// Tests assert length == 6.
  static const List<String> kStillDependentPaths = [
    'active_continuation_identity',
    'completion_gating',
    'settlement_trigger',
    'rollback_target',
    'non_cutover_non_upgraded_sessions_baseline_path',
    'compatibility_anchor_qa_baseline_reference',
  ];

  /// The 3 distinct layer separations that must remain visible in code.
  /// Tests assert length == 3 and all three phrases present.
  static const List<String> kLayerSeparationAssertions = [
    'true_exit_candidate_not_equal_true_exit_started',
    'true_exit_started_not_equal_true_exit_absorbed',
    'uplift_absorb_readiness_not_equal_active_baseline_uplift_absorbed',
  ];

  /// The active DB/API baseline this round. Tests assert exact equality.
  static const String kActiveDbApiBaseline = 'v0.2.1';

  /// A-checkpoint pass-gate conditions (RF-P3.3.14-004).
  /// All 5 must hold before Room 4 may proceed to B.
  /// Tests assert length == 5.
  static const List<String> kAPassGateConditions = [
    'all_six_hard_precondition_groups_written_into_code',
    'six_still_dependent_paths_listed_explicitly',
    'thirty_two_overclaim_guardrails_in_place',
    'no_must_hold_mismatch_detected',
    'closeout_summary_sufficient_for_room_1_b_authorization',
  ];

  /// Forbidden transitions at A layer — things A must NOT express.
  /// Tests assert length == 6.
  static const List<String> kForbiddenATransitions = [
    'runtime_owner_shift_completed',
    'review_group_true_exit_started',
    'active_db_api_baseline_uplift_absorbed',
    'final_fact_owner_shift',
    'home_page_default_route_change',
    'cleanup_old_path_purge_completed',
  ];

  /// Canonical meaning of this lock — A checkpoint pins the judgment,
  /// it does NOT advance runtime truth.
  /// Tests assert this contains 'pinned_not_runtime_truth_advanced'.
  static const String kCanonicalMeaning =
      'final_cutover_judgment_lock_v1_pins_a_checkpoint_judgment_'
      'pinned_not_runtime_truth_advanced_and_does_not_equal_'
      'full_cutover_completed_or_true_exit_started_or_uplift_absorbed';
}

// ============================================================================
// Merged from: same_round_cleanup_gate.dart
// ============================================================================
/// same_round_cleanup_gate_v1 (FROZEN, P3.3.14)
///
/// C-checkpoint entry gate for Same-Round Absorb / Cleanup Closeout.
/// Pins the entry preconditions that must all hold before Room 4 may
/// propose C entry, the stop-at-B conditions that force the round to
/// close at B, and the 6-step same-round closeout write-back order.
///
/// Three lifecycle states are pinned:
///   - not_ready — Round must stop at B
///   - ready_for_c — All 6 entry conditions hold, Room 1 pin pending
///   - cleanup_absorbed — Post-C absorbed decision (NOT reachable this round)
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.14-018: cleanup C-checkpoint absorption entry conditions —
///                 6 entry preconditions.
/// RF-P3.3.14-019: cleanup stop-at-B conditions — 6 conditions that
///                 force stop at B.
/// RF-P3.3.14-020: same-round absorb / cleanup write-back order —
///                 6 immutable steps.

/// The 3 lifecycle states of the same-round cleanup gate.
enum SameRoundCleanupGateState {
  /// State 1: not ready — the round MUST stop at B. C is not entered.
  notReady,

  /// State 2: ready-for-C — all 6 entry conditions hold; Room 4 may
  /// propose C entry but Room 1's explicit pin is still required.
  readyForC,

  /// State 3: cleanup absorbed — post-C absorbed decision. This is
  /// the end state and NOT reachable this round.
  cleanupAbsorbed,
}

abstract final class SameRoundCleanupGate {
  /// Current status — gate pinned, ready-for-C discussion only.
  /// Tests assert this exact string.
  static const String kStatus =
      'same_round_cleanup_gate_pinned_c_entry_gated_not_cleanup_absorbed';

  /// The 6 C-entry preconditions (RF-P3.3.14-018). All must hold.
  /// Tests assert length == 6.
  static const List<String> kSixCEntryConditions = [
    'a_checkpoint_passed',
    'b_checkpoint_runtime_truth_regression_and_rollback_evidence_package_passed',
    'review_group_true_exit_absorb_gate_passed',
    'db_api_uplift_absorb_gate_passed',
    'no_overclaim_no_major_change_no_fact_owner_shift_still_holds',
    'room_1_explicit_pin_for_same_round_cleanup_allowed',
  ];

  /// The 6 stop-at-B conditions (RF-P3.3.14-019). If any fires, the
  /// round MUST close at B and NOT enter C.
  /// Tests assert length == 6.
  static const List<String> kSixStopAtBConditions = [
    'current_runtime_truth_silently_altered',
    'active_continuation_switched_to_local_path',
    'review_group_true_exit_evidence_incomplete_or_absorb_evidence_incomplete',
    'final_fact_owner_boundary_broken',
    'rollback_hold_fallback_copy_incomplete',
    'user_side_overclaim_of_cutover_or_exited_or_absorbed_or_cleaned_up',
  ];

  /// The 6-step immutable same-round closeout write-back order
  /// (RF-P3.3.14-020). Tests assert length == 6 and EXACT order.
  static const List<String> kSixStepWritebackOrder = [
    'step_1_r2_tech_note_closeout',
    'step_2_r3_rules_note_closeout',
    'step_3_r5_ui_preflight_closeout',
    'step_4_r1_same_round_closeout_pin',
    'step_5_db_api_writeback_to_seam_marker_layer_only',
    'step_6_runtime_baseline_update_only_if_r1_separately_pins_post_true_closeout',
  ];

  /// Items that C may DISCUSS (not necessarily absorb) once the gate
  /// is open. Tests assert length == 4.
  static const List<String> kCDiscussionScope = [
    'review_group_true_exit_absorb_qualification',
    'db_api_uplift_absorbed_decision_readiness',
    'cleanup_old_path_purge_same_round_tail_absorption_qualification',
    'same_round_closeout_writeback_order_application',
  ];

  /// Forbidden claims even at C discussion level.
  /// Tests assert length == 6.
  static const List<String> kForbiddenClaims = [
    'cleanup_already_completed',
    'true_exit_already_absorbed',
    'uplift_already_absorbed',
    'old_path_already_purged',
    'full_cutover_closeout_already_pinned',
    'runtime_truth_already_upgraded',
  ];

  /// Default state this round — not reached C. Tests assert this
  /// equals `notReady` name string.
  static const String kDefaultStateThisRound = 'notReady';

  /// Semantic boundary: gate pin ≠ gate open; discussion scope ≠
  /// absorbed decision.
  /// Tests assert this contains 'gate_pin_not_equal_gate_open'.
  static const String kSemanticBoundary =
      'same_round_cleanup_gate_pin_not_equal_gate_open_and_discussion_scope_'
      'not_equal_absorbed_decision';
}

// ============================================================================
// P3.3.15 — Direct Cutover Scaffolding Round Anchor (flag stays false)
// ============================================================================
/// P3_3_15_DirectCutoverScaffoldingRoundAnchor (FROZEN, P3.3.15)
///
/// Documents the outcome of the P3.3.15 round. Room 1 handed off
/// `R1_to_R4_P3_3_15_DirectCutover_Execution_Handoff_v0.1.md` as a
/// "direct cutover round" with 4 tracks. Analysis revealed a hard
/// contradiction with the out-of-scope list (no API core semantics
/// rewrite + final fact / settlement owner stays at backend). A real
/// runtime source switch cannot coexist with those constraints
/// because `submitReviewAttempt` is keyed on backend-issued group IDs
/// and returns settlement + dailyGoalStatus as part of its response.
///
/// User decision: build the missing local-serving scaffolding as real
/// runtime code (S1 / S2 / S4), but leave the cutover flag false.
/// S3 (settlement ownership for local-origin sessions) is parked on
/// a future Room 1 pin.
///
/// Tracks from the handoff:
///   - Track A (direct serving cutover) → SCAFFOLDING ONLY, flag false
///   - Track B (review_group true exit absorb) → PARKED (blocks on S3)
///   - Track C (DB/API uplift absorbed)       → GOVERNANCE-DOC ONLY
///   - Track D (cleanup / old-path purge)     → SKIPPED
///
/// This is NOT a real cutover. It is a scaffolding-landed round that
/// makes a future flag flip a small, well-defined change.
///
/// ============================================================================
/// Landed components (S1 + S2 + S4)
/// ============================================================================
///
///   S1 — `lib/core/serving/local_review_queue_builder.dart`
///        Reads FSRS due cards, joins against `cached_words`,
///        assembles a `ReviewGroup` DTO with a `local_`-prefixed
///        group ID. Dormant in prod; flag-gated.
///
///   S2 — `lib/features/review/review_page.dart` branching
///        `_loadReviewGroup()` now has a flag-gated branch on the
///        seam selection. In prod the flag is false so the branch
///        is never taken. `_onRate()` has a hard assertion refusing
///        any `local_`-prefixed group ID (which would silently
///        corrupt backend state).
///
///   S4 — `lib/core/serving/rollback_hold_fallback_runtime_watcher.dart`
///        First runtime consumer of the P3.3.14 `RollbackHold
///        FallbackState` enum. Pure function, computes state from
///        seam selection + failure signals.
///
/// ============================================================================
/// NOT landed this round (and why)
/// ============================================================================
///
///   - `isReviewPageNonContinuationCutoverEnabled` flipped to true.
///     Parked on S3 — Room 1 must decide whether local-origin
///     sessions round-trip through backend (requires API contract
///     change) or skip backend settlement (requires final fact
///     owner shift). Both are out of scope this round.
///
///   - `review_group` true exit absorbed. Blocked on flag flip.
///
///   - Active DB/API baseline uplift. Deferred to
///     governance-document-only patch drafts; there is no runtime
///     surface to absorb into this round.
///
///   - Cleanup / old-path purge. Tracks B/C/D depend on Track A
///     having produced real absorption, which did not happen.

/// Round anchor for P3.3.15 — direct-cutover scaffolding landed, flag
/// still false, not a real cutover.
abstract final class P3315DirectCutoverScaffoldingRoundAnchor {
  /// Canonical status string. Tests assert this contains
  /// `'scaffolding_landed'` and `'flag_still_false'`.
  static const String kStatus =
      'scaffolding_landed_flag_still_false_not_a_real_cutover';

  /// The 4 landed components. Tests assert length == 4 and exact
  /// membership.
  static const List<String> kLandedComponents = [
    'local_review_queue_builder',
    'reviewpage_flag_gated_branching_dormant',
    'rollback_hold_fallback_runtime_watcher_wired',
    'round_anchor_documented_in_merged_gate_file',
  ];

  /// The 4 NOT-landed items. Tests assert length == 4 and exact
  /// membership.
  static const List<String> kNotLanded = [
    'cutover_flag_flipped_to_true',
    'settlement_ownership_decided_for_local_origin_sessions',
    'review_group_true_exit_absorbed',
    'cleanup_old_path_purged',
  ];

  /// Blocking decisions that must be resolved by Room 1 before any
  /// subsequent round can flip the cutover flag. Tests assert
  /// length == 1.
  static const List<String> kBlockingDecisions = [
    's3_settlement_ownership_for_local_origin_sessions_requires_room_1_decision',
  ];

  /// Outcome per handoff track. Tests assert exact map contents.
  static const Map<String, String> kTracksFromHandoff = {
    'track_a_direct_serving_cutover': 'scaffolding_only_flag_false',
    'track_b_review_group_true_exit_absorb': 'parked_blocks_on_s3',
    'track_c_db_api_uplift_absorbed': 'governance_doc_only_no_runtime_surface',
    'track_d_cleanup_old_path_purge': 'skipped_depends_on_a_b_c',
  };

  /// Still-forbidden actions (same set as v4/v5 fact-owner-boundary).
  /// Tests assert length == 8.
  static const List<String> kStillForbiddenActions = [
    'local_completion_confirmation',
    'ledger_arrival_via_new_path',
    'daily_goal_achievement_via_new_path',
    'streak_update_via_new_path',
    'review_fact_switched_to_local',
    'new_main_path_live',
    'review_group_exited',
    'uplift_completed',
  ];

  /// Forbidden user-visible claims this round. Tests assert presence
  /// of key phrases.
  static const List<String> kForbiddenClaims = [
    '本地 serving 已启用',
    '本地复习主链路已生效',
    'cutover 已完成',
    'review_group 已退场',
    'settlement 已本地化',
    '新主链路已生效',
    'daily_goal 已由本地结算',
    'streak 已由本地续上',
    'local_origin session 已并入最终事实',
    'uplift 已 absorbed',
  ];

  /// The canonical rollback target — unchanged from P3.3.9. Tests
  /// assert exact string equality.
  static const String kRollbackTarget =
      'cloud_review_group_current_runtime_path';

  /// Semantic boundary: scaffolding landing != runtime truth
  /// advancement. Tests assert this contains
  /// `'scaffolding_landing_does_not_advance_runtime_truth'`.
  static const String kSemanticBoundary =
      'scaffolding_landing_does_not_advance_runtime_truth_and_cutover_flag_'
      'flip_remains_blocked_on_room_1_settlement_ownership_decision';

  /// The load-bearing prefix on local-origin group IDs. Mirrored from
  /// `LocalReviewQueueBuilder.kLocalGroupIdPrefix`. Tests assert
  /// equality.
  static const String kLocalOriginGroupIdPrefix = 'local_';

  /// The load-bearing group status for local-origin sessions.
  /// Mirrored from `LocalReviewQueueBuilder.kLocalGroupStatus`.
  /// Tests assert equality.
  static const String kLocalOriginGroupStatus = 'local_origin';

  /// Previous round anchor marker. Tests assert exact string.
  static const String kPreviousStage = 'p3_3_14_final_cutover_program_round';

  /// Current round anchor marker. Tests assert this contains
  /// `'p3_3_15_direct_cutover_scaffolding'`.
  static const String kCurrentStage =
      'p3_3_15_direct_cutover_scaffolding_landed_flag_still_false';
}

// ============================================================================
// P3.3.16 — Real Cutover Round Anchor
// ============================================================================
//
// This round: flag flipped, seam wired, new local-batch endpoint live.
// Non-continuation ReviewPage loads now serve from local FSRS queue.
// Active continuations still routed to cloud (Priority 1 retained anchor).
//
// S3 resolution: Option A — POST /review-attempts/local-batch.
//
/// Round anchor for P3.3.16 — the real cutover round.
/// Immutable constants used by delivery tests as a machine-readable
/// record of what this round landed and what it explicitly left alone.
abstract final class P3316RealCutoverRoundAnchor {
  /// Round status — flag is flipped and cutover is active.
  static const String kStatus =
      'flag_flipped_cutover_active_local_serving_enabled';

  /// How S3 (settlement ownership) was resolved.
  static const String kS3Resolution = 'option_a_new_local_batch_endpoint';

  /// The new backend endpoint that resolves S3.
  static const String kNewEndpoint = 'POST /review-attempts/local-batch';

  /// Components landed this round.
  static const List<String> kLandedComponents = [
    'review_serving_seam_priority3_wired_to_local_non_continuation',
    'is_review_page_non_continuation_cutover_enabled_flipped_true',
    'post_review_attempts_local_batch_backend_endpoint',
    'review_page_handle_local_session_rating_method',
    'local_session_attempts_accumulator_field',
  ];

  /// The retained anchor: active continuations still go to cloud.
  /// Priority 1 in ReviewServingSeam is unchanged.
  static const String kRetainedAnchor =
      'active_continuation_still_routes_to_cloud_via_priority1';

  /// What was explicitly NOT done this round (still out of scope).
  static const List<String> kNotDone = [
    'review_group_endpoint_removed_or_deprecated',
    'settlement_moved_fully_to_local',
    'db_schema_changed',
    'home_page_modified',
    'study_page_modified',
  ];

  /// Forbidden claims — these must NOT appear in any user-facing copy
  /// or in any code comment that asserts a state beyond this round.
  static const List<String> kForbiddenClaims = [
    'review_group已退场',
    'settlement已本地化',
    'FSRS已接管所有事实',
    '后端已不再参与复习结算',
    '本地serving已完全取代云端',
    'cutover已完成所有阶段',
  ];

  /// Previous round marker (for chain verification).
  static const String kPreviousStage =
      'p3_3_15_direct_cutover_scaffolding_landed_flag_still_false';

  /// Current round marker.
  static const String kCurrentStage =
      'p3_3_16_real_cutover_flag_flipped_local_serving_active';
}

