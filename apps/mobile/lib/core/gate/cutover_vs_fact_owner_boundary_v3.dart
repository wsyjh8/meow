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
library;

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
