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
library;

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
