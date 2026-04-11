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
library;

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
