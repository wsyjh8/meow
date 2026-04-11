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
library;

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
