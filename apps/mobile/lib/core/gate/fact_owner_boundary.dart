/// fact_owner_boundary.dart (MERGED in P3.3.14 consolidation round)
///
/// Consolidated fact-owner / fact-settlement / cutover-vs-fact-owner boundary contracts from P3.3.8 through P3.3.14. Core invariant: serving seam advancement does NOT equal final fact owner advancement. The 5 final facts (effective_review_fact, daily_goal_progress_and_completion_owner, reward_settlement_ledger_arrival_owner, check_in_learning_day_streak_owner, completion_arrival_class_primary_feedback_truth_source) remain backend-authoritative throughout all rounds.
///
/// This file was consolidated from 8 original per-round files to
/// reduce gate-file sprawl. Class names and constants are preserved
/// exactly so all existing tests continue to work after updating
/// their import paths.
library;

// ============================================================================
// Merged from: fact_settlement_cutover_boundary.dart
// ============================================================================
/// fact_settlement_cutover_boundary_v1 (FROZEN, P3.3.8)
///
/// Extends P3.3.6's `fact_ingest_boundary_contract.dart` with cutover-
/// specific constants. The boundary remains UNCROSSED — final facts
/// stay cloud-owned regardless of any future serving owner shift.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.8-005: serving source must not shift before fact-settlement
///                boundary is locked.
/// RF-P3.3.8-009: final facts continue to use backend as truth source:
///                  - effective review fact
///                  - daily goal completion
///                  - reward settlement / account credit
///                  - check_in / learning_day / streak
/// RF-P3.3.8-010: local evidence can at most enter stronger active
///                ingest path candidate — NOT become fact owner.
/// RF-P3.3.8-011: overclaim list forbidden.

/// Contract anchor constants for the fact/settlement cutover boundary.
///
/// This class expresses ROOM 1's decision that the fact/settlement
/// boundary is NOT a cut candidate in P3.3.8. Runtime code does not
/// consume these constants; they exist for tests and cross-room doc
/// references.
abstract final class FactSettlementCutoverBoundary {
  /// Cutover boundary status — NOT crossed this round.
  /// Tests assert this contains 'uncrossed'.
  static const String kCutoverBoundaryStatus = 'uncrossed_fact_owner_cloud';

  /// Facts that continue to be cloud-owned this round.
  /// Superset of P3.3.6's `kCloudOwnedFinalFacts`, adding explicit
  /// owner-name entries for the status fields.
  static const List<String> kFinalFactsStillCloudOwned = [
    'effective_review_fact',
    'daily_goal_progress',
    'daily_goal_status_final_fact_owner',
    'session_validation_status_final_fact_owner',
    'reward_settlement_ledger',
    'reward_settlement_status_final_fact_owner',
    'check_in_learning_day_streak',
    'learning_day_streak_final_fact_owner',
    'reward_source_events_ledger_settlements_backend_write_chain',
  ];

  /// Local evidence maximum scope this round.
  /// Local evidence can ONLY enter these layers — never become a
  /// fact owner.
  static const List<String> kLocalEvidenceAllowedScope = [
    'stronger_active_ingest_path_candidate_discussion',
    'accept_reject_duplicate_rule_stability_assessment',
    'writeback_migration_entry_conditions',
  ];

  /// Forbidden local fact owner actions.
  /// Tests assert none of these become code-side actions.
  static const List<String> kForbiddenLocalFactOwnerActions = [
    'direct_ledger_modification',
    'direct_daily_goal_completion_state_change',
    'direct_streak_learning_day_fact_ownership',
    'direct_cloud_settlement_owner_replacement',
  ];

  /// Forbidden overclaims (RF-P3.3.8-011).
  /// Tests assert none of these appear in any UI copy.
  static const List<String> kForbiddenOverclaims = [
    'local 已接管 review facts',
    '本地已主导 daily completion 判断',
    '本地结果已写回最终事实',
    '奖励已由本地计划正式结算',
    'streak / learning_day 已由本地主导',
    '本地已直接记为有效复习',
  ];
}

// ============================================================================
// Merged from: fact_owner_guardrail.dart
// ============================================================================
/// fact_owner_guardrail_v1 (FROZEN, P3.3.9)
///
/// Extends P3.3.8's `fact_settlement_cutover_boundary_v1` with cutover-
/// specific guardrails. The boundary remains UNCROSSED this round —
/// even though the serving seam has been introduced, no final fact
/// owner has shifted.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.9-011: following final facts must remain backend/cloud fact
///                layer: valid review fact, today's goal completion,
///                reward settlement/account arrival, check_in/
///                learning_day/streak.
///
/// RF-P3.3.9-012: stronger ingest path at most allows: stronger evidence
///                ingestion, clearer accept/reject/duplicate rules,
///                minimal transfer directly related to first-cutover
///                seam; forbidden: local directly alters ledger,
///                daily_goal completion, streak/learning_day final fact,
///                replaces settlement owner.
///
/// RF-P3.3.9-013: forbidden overclaim wording.

abstract final class FactOwnerGuardrail {
  /// Final facts that remain backend/cloud fact layer (RF-P3.3.9-011).
  /// Same 4 canonical final facts from P3.3.6 + P3.3.8 (unchanged).
  static const List<String> kFinalFactsRemainCloudOwned = [
    'valid_review_fact',
    'today_goal_completion',
    'reward_settlement_account_arrival',
    'check_in_learning_day_streak',
  ];

  /// Stronger ingest path maximum allowed scope (RF-P3.3.9-012).
  /// Stronger ingest MUST NOT exceed this list — any expansion requires
  /// a Room 1 escalation.
  static const List<String> kStrongerIngestAllowedScope = [
    'stronger_evidence_ingestion',
    'clearer_accept_reject_duplicate_rules',
    'minimal_transfer_related_to_first_cutover_seam',
    'accept_reject_duplicate_candidate_result_standardization',
    'attempt_progress_completion_candidate_event_naming',
    'ingest_precondition_postcondition_hold_reason',
    'idempotency_dedup_retry_seam_floor',
  ];

  /// Forbidden local fact owner actions (RF-P3.3.9-012).
  /// Tests assert local code MUST NOT perform any of these.
  static const List<String> kForbiddenLocalFactOwnerActions = [
    'local_directly_alters_ledger',
    'local_directly_alters_daily_goal_completion',
    'local_directly_alters_streak_learning_day_final_fact',
    'local_replaces_settlement_owner',
  ];

  /// Forbidden overclaim wording (RF-P3.3.9-013).
  /// Tests assert none of these appear in any visible UI copy.
  static const List<String> kForbiddenOverclaims = [
    'local 已接管 review fact',
    'local 已接管 daily completion 判断',
    '本地结果已写回最终事实',
    '奖励已由本地 path 正式结算',
    'streak / learning_day 已由本地 serving 续上',
    '本地已直接记为有效复习',
    'cutover 已完成',
    '新主链路已生效',
    '现在已按本地主 serving 运行',
  ];

  /// Canonical rule: result-type feedback only after backend confirms
  /// the final fact. `ReviewPage._onRate()` already obeys this — the
  /// settlement snackbar is shown only after cloud returns a settled
  /// result.
  static const String kResultFeedbackRule =
      'backend_confirmed_final_fact_only_drives_result_feedback';
}

// ============================================================================
// Merged from: cutover_vs_fact_owner_boundary_v2.dart
// ============================================================================
/// cutover_vs_fact_owner_boundary_v2 (FROZEN, P3.3.10)
///
/// Extends P3.3.9's `fact_owner_guardrail_v1` with stronger-ingest
/// judgment-ready allowed advancements. Canonical rule: fuller cutover
/// and final fact owner remain DECOUPLED.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.10-002: fuller cutover must not cross this boundary.
/// RF-P3.3.10-008: final facts (effective review, daily goal completion,
///                 reward settlement, check_in/learning_day/streak) must
///                 continue using backend as truth source.
/// RF-P3.3.10-009: stronger ingest candidate can advance to uplift-
///                 judgment-ready seam only.
/// RF-P3.3.10-010: overclaim prohibitions continue.

abstract final class CutoverVsFactOwnerBoundaryV2 {
  /// Canonical rule: fuller cutover and final fact owner are DECOUPLED.
  /// Tests assert this exact string.
  static const String kCanonicalRule =
      'fuller_cutover_vs_final_fact_owner_decoupled_this_round';

  /// Final facts that remain backend-authoritative.
  /// Same 4 canonical final facts from P3.3.6/P3.3.8/P3.3.9, plus the
  /// completion / arrival feedback (unchanged).
  static const List<String> kFinalFactsRemainBackendAuthoritative = [
    'effective_review_fact',
    'daily_goal_progress_and_completion',
    'reward_settlement_ledger_arrival',
    'check_in_learning_day_streak',
    'completion_arrival_class_main_feedback',
  ];

  /// NEW stronger-ingest allowed advancements in v2 (P3.3.10 additions).
  /// These go BEYOND P3.3.9 v1's evidence-path scope.
  /// Tests assert all 5 are present.
  static const List<String> kStrongerIngestAllowedAdvancementsV2 = [
    'accept_reject_duplicate_result_standardization',
    'attempt_progress_completion_candidate_clearer_naming',
    'stronger_ingest_precondition_postcondition',
    'hold_reason_reject_reason_mismatch_bucket_explicitness',
    'no_final_fact_owner_switch_assertion_more_stable_landing',
  ];

  /// Still-forbidden actions (reinforced from P3.3.9 v1).
  /// Tests assert all canonical forbidden actions are present.
  static const List<String> kStillForbiddenActions = [
    'local_serving_result_directly_modifies_ledger',
    'local_serving_result_directly_advances_daily_goal_completion',
    'local_serving_result_directly_continues_streak_learning_day',
    'local_serving_result_directly_produces_user_fact',
    'stronger_ingest_elevation_to_final_fact_write',
  ];

  /// Forbidden overclaims (extends P3.3.9 v1).
  /// Tests assert none of these appear in any visible UI copy.
  static const List<String> kForbiddenOverclaims = [
    'local 已接管 review facts',
    'local 已接管 daily completion 判断',
    '本地结果已写回最终事实',
    '奖励已由本地 path 正式结算',
    'streak / learning_day 已由本地 serving 续上',
    '本地已直接记为有效复习',
    '本地 evidence 已成为 final fact',
    '学习事实已更新到最终结果',
  ];

  /// Canonical meaning: serving subset can fuller, ingest candidate
  /// stronger; final fact owner CANNOT yet switch.
  /// Tests assert this contains 'final_fact_owner_cannot_yet_switch'.
  static const String kCanonicalMeaning =
      'serving_subset_can_fuller_ingest_candidate_stronger_final_fact_owner_cannot_yet_switch';
}

// ============================================================================
// Merged from: cutover_vs_fact_owner_boundary_v3.dart
// ============================================================================
/// cutover_vs_fact_owner_boundary_v3 (FROZEN, P3.3.11)
///
/// Extends P3.3.10's v2 with execution-ready binding prep specificity.
/// Canonical rule: stronger-ingest binding may solidify, serving seam
/// may widen, but final fact owner MUST remain backend.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.11-011: final facts (effective review, daily goal completion,
///                 reward settlement, check_in/learning_day/streak,
///                 completion-arrival main feedback) must continue using
///                 backend/cloud fact layer as source of truth.
/// RF-P3.3.11-012: stronger ingest candidate may advance only to:
///                 validated stronger-ingest candidate execution layer,
///                 clearer accept/reject/duplicate rules, explicit
///                 precondition/postcondition/hold-reason ownership,
///                 and ingest contract binding directly tied to
///                 fuller-cutover execution subset.
/// RF-P3.3.11-013: claims forbidden (6 new phrases).

abstract final class CutoverVsFactOwnerBoundaryV3 {
  /// Canonical rule: stronger-ingest binding may solidify; serving seam
  /// may widen; final fact owner must remain backend.
  /// Tests assert this contains 'final_fact_owner_must_remain_backend'.
  static const String kCanonicalRule =
      'stronger_ingest_binding_may_solidify_serving_seam_may_widen_final_fact_owner_must_remain_backend';

  /// Final facts that CANNOT switch with serving seam.
  /// Same 5 canonical facts from P3.3.10 v2 (unchanged).
  static const List<String> kFinalFactsRemainBackendAuthoritative = [
    'effective_review_final_fact',
    'daily_goal_progress_and_completion_owner',
    'reward_settlement_ledger_arrival_owner',
    'check_in_learning_day_streak_owner',
    'completion_arrival_main_feedback_final_truth_source',
  ];

  /// NEW v3 stronger-ingest execution-ready binding allowed advancements.
  /// These go beyond P3.3.10 v2's judgment-level advancements.
  /// Tests assert length == 5 and all canonical items present.
  static const List<String> kStrongerIngestExecutionReadyBindingV3 = [
    'accept_reject_duplicate_binding_more_solid',
    'progress_candidate_completion_candidate_preconditions_postconditions_clearer',
    'hold_reason_rollback_ownership_more_explicit',
    'no_final_fact_owner_switch_assertion_more_stable',
    'minimal_ingest_binding_aligned_with_widened_serving_subset',
  ];

  /// Still-forbidden actions (reinforced from v2, with 2 new v3 items).
  /// Tests assert canonical forbidden actions present.
  static const List<String> kStillForbiddenActions = [
    'local_serving_result_directly_modifies_ledger',
    'local_serving_result_directly_advances_daily_goal_completion',
    'local_serving_result_directly_continues_streak_learning_day',
    'local_serving_result_directly_produces_user_fact',
    'stronger_ingest_elevation_to_final_fact_write',
    // NEW in v3:
    'completion_determined_by_local_stronger_path',
    'today_goal_auto_advanced_via_new_seam',
  ];

  /// Forbidden overclaims (extends v2 with 6 NEW RF-P3.3.11-013 phrases).
  /// Tests assert ALL NEW RF-P3.3.11-013 phrases are present.
  static const List<String> kForbiddenOverclaims = [
    // From P3.3.10 v2 (still forbidden):
    'local 已接管 review facts',
    '本地结果已写回最终事实',
    '奖励已由本地 path 正式结算',
    'streak / learning_day 已由本地 serving 续上',
    '本地已直接记为有效复习',
    // NEW in v3 (RF-P3.3.11-013):
    '本地已确认完成',
    '奖励已到账',
    '今日目标已达成',
    '连续学习已更新',
    '复习事实已切到本地',
    '新主链路已生效',
  ];

  /// Canonical meaning (unchanged from v2).
  /// Tests assert this contains 'final_fact_owner_cannot_yet_switch'.
  static const String kCanonicalMeaning =
      'serving_subset_can_fuller_ingest_candidate_stronger_final_fact_owner_cannot_yet_switch';
}

// ============================================================================
// Merged from: cutover_vs_fact_owner_boundary_v4.dart
// ============================================================================
/// cutover_vs_fact_owner_boundary_v4 (FROZEN, P3.3.12)
///
/// Extends P3.3.11's v3 with stronger-ingest absorb-judgment candidate
/// advancement boundary. Canonical rule: serving seam advancement does
/// NOT equal final fact owner advancement.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.12-013: final facts must continue using backend as authoritative
///                 truth source.
/// RF-P3.3.12-014: stronger-ingest candidate limited to absorb-judgment
///                 level advancement only.
/// RF-P3.3.12-015: 12 overclaim expressions forbidden.

abstract final class CutoverVsFactOwnerBoundaryV4 {
  /// Canonical rule.
  /// Tests assert this contains
  /// 'serving_seam_advancement_does_not_equal_final_fact_owner_advancement'.
  static const String kCanonicalRule =
      'serving_seam_advancement_does_not_equal_final_fact_owner_advancement';

  /// Final facts that MUST continue backend-authoritative.
  /// Same 5 canonical facts from P3.3.11 v3 (unchanged).
  static const List<String> kFinalFactsRemainBackendAuthoritative = [
    'effective_review_fact',
    'daily_goal_progress_and_completion_owner',
    'reward_settlement_ledger_arrival_owner',
    'check_in_learning_day_streak_owner',
    'completion_arrival_class_primary_feedback_truth_source',
  ];

  /// NEW v4 stronger-ingest absorb-judgment advancements.
  /// 5 advancements allowed beyond P3.3.11 v3's execution-ready bindings.
  static const List<String> kStrongerIngestAbsorbJudgmentAdvancementsV4 = [
    'accept_reject_duplicate_binding_more_stable',
    'progress_candidate_completion_candidate_precondition_postcondition_clarity',
    'hold_reason_rollback_ownership_more_explicit',
    'no_final_fact_owner_switch_assertion_stronger',
    'minimal_ingest_binding_aligned_with_absorb_candidate_subset',
  ];

  /// Still-forbidden actions (reinforced from v3).
  /// 8 items including new v4 additions.
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

  /// Forbidden overclaims — 12 canonical RF-P3.3.12-015 phrases.
  /// Tests assert all 12 present.
  static const List<String> kForbiddenOverclaims = [
    'local 已接管 review fact',
    'local 已接管 daily completion 判断',
    '本地结果已写回最终事实',
    '奖励已由新 path 正式结算',
    'streak / learning_day 已由新 path 续上',
    'daily goal 已由新 serving seam 自动推进',
    'completion 已由 local stronger path 裁定',
    'review_group 已退场',
    'active DB/API baseline 已升级',
    'uplift 已 absorbed',
    'fuller cutover 已完成',
    '新主链路已生效',
  ];

  /// Canonical meaning: serving subset may widen for absorb-candidate;
  /// ingest candidate may solidify for absorb-judgment; final fact owner
  /// CANNOT yet switch.
  static const String kCanonicalMeaning =
      'serving_subset_may_widen_for_absorb_candidate_ingest_candidate_may_solidify_for_absorb_judgment_final_fact_owner_cannot_yet_switch';
}

// ============================================================================
// Merged from: cutover_vs_fact_owner_boundary_v5.dart
// ============================================================================
/// cutover_vs_fact_owner_boundary_v5 (FROZEN, P3.3.13)
///
/// Extends P3.3.12's v4 with stronger-ingest absorb-readiness candidate
/// advancement boundary. Canonical rule remains: serving seam
/// advancement does NOT equal final fact owner advancement. The 5
/// backend-authoritative final facts are unchanged from v3/v4.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.13-013: final facts must continue using backend / cloud as
///                 the authoritative truth source.
/// RF-P3.3.13-014: stronger-ingest candidate max reach = absorb-
///                 readiness level. Cannot elevate to active serving
///                 or final fact owner.
/// RF-P3.3.13-015: five result types never follow any serving-seam
///                 switch — they stay cloud-owned.
/// RF-P3.3.13-016: 12 forbidden overclaim expressions.
/// RF-P3.3.13-017: rollback target stays fixed to
///                 `cloud_review_group_current_runtime_path`.

abstract final class CutoverVsFactOwnerBoundaryV5 {
  /// Canonical rule. Tests assert this contains
  /// 'serving_seam_advancement_does_not_equal_final_fact_owner_advancement'.
  static const String kCanonicalRule =
      'serving_seam_advancement_does_not_equal_final_fact_owner_advancement';

  /// Final facts that MUST continue backend-authoritative.
  /// Same 5 canonical facts from P3.3.11 v3 / P3.3.12 v4 (unchanged).
  static const List<String> kFinalFactsRemainBackendAuthoritative = [
    'effective_review_fact',
    'daily_goal_progress_and_completion_owner',
    'reward_settlement_ledger_arrival_owner',
    'check_in_learning_day_streak_owner',
    'completion_arrival_class_primary_feedback_truth_source',
  ];

  /// NEW v5 stronger-ingest absorb-readiness advancements.
  /// 5 advancements allowed beyond P3.3.12 v4's absorb-judgment
  /// bindings.
  static const List<String> kStrongerIngestAbsorbReadinessAdvancementsV5 = [
    'accept_reject_duplicate_binding_absorb_readiness_ready',
    'progress_completion_candidate_absorb_readiness_orchestration',
    'observability_parity_rollback_hold_absorb_readiness_complete',
    'no_final_fact_owner_switch_assertion_strongest',
    'minimal_ingest_binding_aligned_with_execution_subset_v2',
  ];

  /// Still-forbidden actions (reinforced from v4).
  /// 8 items — same set as v4, since no new forbidden surface opens
  /// this round.
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

  /// Forbidden overclaims — 12 canonical RF-P3.3.13-016 phrases.
  /// Tests assert all 12 present.
  static const List<String> kForbiddenOverclaims = [
    'local 已接管 review fact',
    'local 已接管 daily completion 判断',
    '本地结果已写回最终事实',
    '奖励已由新 path 正式结算',
    'streak / learning_day 已由新 path 续上',
    'daily goal 已由新 serving seam 自动推进',
    'completion 已由 local stronger path 裁定',
    'review_group 已退场',
    'active DB/API baseline 已升级',
    'uplift 已 absorbed',
    'fuller cutover 已完成',
    '新主链路已生效',
  ];

  /// Canonical meaning: serving subset may widen for execution-subset-
  /// v2; ingest candidate may solidify for absorb-readiness; final
  /// fact owner CANNOT yet switch.
  static const String kCanonicalMeaning =
      'serving_subset_may_widen_for_execution_subset_v2_ingest_candidate_may_solidify_for_absorb_readiness_final_fact_owner_cannot_yet_switch';

  /// Previous stage (P3.3.12 v4 absorb-judgment binding).
  static const String kPreviousStage =
      'p3_3_12_absorb_judgment_binding_level';

  /// Current stage (P3.3.13 v5 absorb-readiness binding).
  static const String kCurrentStage =
      'p3_3_13_absorb_readiness_binding_level';
}

// ============================================================================
// Merged from: fact_owner_cutover_guardrail.dart
// ============================================================================
/// fact_owner_cutover_guardrail_v1 (FROZEN, P3.3.14)
///
/// Cross-cutting guardrail pinned at A and enforced through B and C.
/// This is the hardest line of the round — no matter how far any
/// serving seam / adapter / execution subset advances, final fact
/// ownership does NOT cross over with it. The backend / cloud fact
/// layer remains the authoritative owner of all 5 final facts.
///
/// `stronger-ingest` is explicitly bounded to candidate / readiness /
/// absorbed-judgment discussion — it may never be promoted directly
/// to final owner in this round.
///
/// This is a COMPANION to the legacy `fact_owner_guardrail.dart`
/// (which was pinned in an earlier phase). The cutover variant
/// extends the rule set specifically for the final cutover program
/// rounds.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.14-015: final-fact backend-locked items — 5 final facts.
/// RF-P3.3.14-016: stronger-ingest candidate / readiness limits — 4
///                 layers that stronger-ingest may not directly alter.
/// RF-P3.3.14-017: fact-owner overclaim prohibitions — 6 user-visible
///                 overclaim phrases that must not appear.

abstract final class FactOwnerCutoverGuardrail {
  /// Canonical rule for the round.
  /// Tests assert this exact string.
  static const String kCanonicalRule =
      'serving_seam_and_execution_subset_advancement_does_not_bring_final_'
      'fact_ownership_advancement';

  /// The 5 final facts that remain backend-authoritative this round
  /// (RF-P3.3.14-015). Tests assert length == 5 and exact membership.
  static const List<String> kFinalFactsRemainBackendAuthoritative = [
    'effective_review_fact',
    'daily_goal_progress_and_completion_owner',
    'reward_settlement_ledger_arrival_owner',
    'check_in_learning_day_streak_owner',
    'completion_arrival_class_primary_feedback_truth_source',
  ];

  /// The 4 layers stronger-ingest is FORBIDDEN from directly
  /// altering this round (RF-P3.3.14-016). Tests assert length == 4.
  static const List<String> kStrongerIngestForbiddenLayers = [
    'review_fact_ownership',
    'daily_completion_and_settlement_ownership',
    'streak_learning_day_ownership',
    'reward_ledger_arrival_ownership',
  ];

  /// The 6 user-visible overclaim phrases forbidden at this guardrail
  /// level (RF-P3.3.14-017). Tests assert length == 6.
  static const List<String> kForbiddenOverclaimPhrases = [
    '本地已直接记为有效复习',
    '今日进度已因本地方案更新',
    '奖励已因新主链路到账',
    'streak 已因 final cutover 续上',
    '学习事实已正式更新',
    '现在你刚刚的结果已写入最终事实',
  ];

  /// Allowed stronger-ingest layers this round — only candidate,
  /// readiness, and absorbed-judgment discussion.
  /// Tests assert length == 3.
  static const List<String> kStrongerIngestAllowedLayers = [
    'candidate_discussion',
    'readiness_discussion',
    'absorbed_judgment_discussion',
  ];

  /// Canonical meaning: serving seam advancement != fact owner shift.
  /// Tests assert this contains 'fact_owner_shift_forbidden_this_round'.
  static const String kCanonicalMeaning =
      'serving_seam_advancement_does_not_equal_final_fact_owner_advancement_'
      'and_stronger_ingest_candidate_progress_does_not_equal_final_owner_'
      'promotion_fact_owner_shift_forbidden_this_round';

  /// Cross-round linkage — this guardrail is a continuation of the
  /// `cutover_vs_fact_owner_boundary_v5` boundary pinned in P3.3.13.
  /// Tests assert this exact string.
  static const String kCrossRoundLinkage =
      'continues_and_narrows_cutover_vs_fact_owner_boundary_v5_from_p3_3_13';
}

// ============================================================================
// Merged from: stronger_ingest_judgment_ready.dart
// ============================================================================
/// stronger_ingest_judgment_ready_v1 (FROZEN, P3.3.10)
///
/// Defines the progression from "evidence-path only" (P3.3.7 shadow
/// classifier) to "validated stronger-ingest candidate layer" (P3.3.10).
/// The candidate layer is judgment-ready — NOT final fact owner.
///
/// ============================================================================
/// Frozen rule referenced
/// ============================================================================
///
/// RF-P3.3.10-009: stronger ingest candidate can only advance to uplift-
///                 judgment-ready seam with clearer accept/reject/
///                 duplicate rules, rollback/hold ownership, and minimal
///                 ingest contract binding to serving subset.
///
/// ============================================================================
/// Stage progression
/// ============================================================================
///
///   P3.3.7 — evidence_path_only (FactIngestShadow pure-local classifier)
///       ↓
///   P3.3.10 — validated stronger ingest candidate layer (judgment-ready)
///       ↓
///   FUTURE — (NOT this round) active fact owner shift

abstract final class StrongerIngestJudgmentReady {
  /// Previous stage (P3.3.7) — evidence-path only, pure-local classifier.
  /// Tests assert this equals the canonical previous stage name.
  static const String kPreviousStage = 'evidence_path_only_p3_3_7';

  /// Current stage (P3.3.10) — validated stronger candidate layer.
  /// Tests assert this contains 'validated_stronger_ingest_candidate_layer'.
  static const String kCurrentStage =
      'validated_stronger_ingest_candidate_layer';

  /// Allowed advancements in the current stage.
  /// These clarify the stronger-ingest candidate WITHOUT elevating it
  /// to fact owner.
  static const List<String> kAllowedAdvancements = [
    'clearer_accept_reject_duplicate_rule_semantics',
    'attempt_progress_completion_candidate_clearer_naming',
    'stronger_ingest_precondition_postcondition',
    'hold_reason_reject_reason_mismatch_bucket_explicit_statement',
    'no_final_fact_owner_switch_assertion_more_stable',
    'more_explicit_rollback_hold_evidence_ownership',
    'minimal_ingest_contract_binding_to_serving_subset',
  ];

  /// Still-forbidden — stronger ingest MUST NOT become fact owner.
  /// Tests assert all canonical forbidden items are present.
  static const List<String> kStillForbidden = [
    'local_stronger_path_elevation_to_final_fact_write',
    'direct_modification_of_reward_ledger',
    'direct_modification_of_daily_goal_completion',
    'direct_modification_of_streak_learning_day_final_fact',
    'direct_substitution_of_settlement_owner',
    'user_visible_taken_over_review_fact_claim',
    'user_visible_written_back_to_final_fact_claim',
  ];

  /// Canonical rule: stronger candidate layer ≠ fact owner layer.
  /// Tests assert this exact string.
  static const String kCanonicalRule =
      'stronger_candidate_layer_not_fact_owner_layer';
}

