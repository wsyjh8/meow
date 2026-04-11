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
library;

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
