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
library;

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
