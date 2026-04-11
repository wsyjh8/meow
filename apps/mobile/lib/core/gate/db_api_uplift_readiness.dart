/// db_api_uplift_readiness_v1 (FROZEN, P3.3.11)
///
/// Promotes P3.3.10's `db_api_uplift_judgment_v1` from judgment-ready to
/// uplift-readiness status. "Uplift-readiness" means "qualified to
/// examine for active baseline uplift" — NOT "active baseline uplift
/// complete". Baselines stay at v0.2.1.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.11-008: only 5 seam families may enter uplift-readiness.
/// RF-P3.3.11-009: seams that must remain at migration/hold/rollback level.
/// RF-P3.3.11-010: conclusions may only be classified as uplift-readiness
///                 candidate — not active uplift absorbed.
library;

/// The 5 seam families eligible for uplift-readiness status.
enum UpliftReadinessSeamFamily {
  /// Family 1: review serving source descriptor seam.
  /// Expresses ReviewPage widened-subset source judgment and source-
  /// hierarchy level. No endpoint core-semantic rewrite.
  reviewServingSourceDescriptorSeam,

  /// Family 2: retained-anchor / fallback posture seam.
  /// Expresses current owner / retained anchor / compatibility anchor /
  /// deprecated candidate / exit-candidate posture at marker layer.
  retainedAnchorFallbackPostureSeam,

  /// Family 3: stronger-ingest path minimal seam.
  /// Accept/reject/duplicate/progress-candidate/completion-candidate
  /// execution-ready stronger binding — NOT final-fact write.
  strongerIngestPathMinimalSeam,

  /// Family 4: rollback / hold / observability seam.
  /// Rollback target, hold reason, evidence bucket, stop-condition,
  /// no-final-fact-owner-switch assertions.
  rollbackHoldObservabilitySeam,

  /// Family 5: source-neutral state / helper / summary contract seam.
  /// Expression and marker layer only — NOT active continuation source
  /// switch itself.
  sourceNeutralStateHelperSummaryContractSeam,
}

abstract final class DbApiUpliftReadiness {
  /// Uplift status — readiness qualified, NOT absorbed.
  /// Tests assert this contains 'uplift_readiness_qualified_not_active'.
  static const String kStatus =
      'uplift_readiness_qualified_not_active_baseline_uplift_complete';

  /// Active DB baseline — unchanged from P3.3.8/9/10.
  /// Tests assert this equals 'v0.2.1'.
  static const String kActiveDbBaselineStillAt = 'v0.2.1';

  /// Active API baseline — unchanged from P3.3.8/9/10.
  /// Tests assert this equals 'v0.2.1'.
  static const String kActiveApiBaselineStillAt = 'v0.2.1';

  /// The 5 seam families eligible for uplift-readiness.
  /// Tests assert length == 5 and all canonical names present.
  static const List<String> kUpliftReadinessSeamFamilies = [
    'review_serving_source_descriptor_seam',
    'retained_anchor_fallback_posture_seam',
    'stronger_ingest_path_minimal_seam',
    'rollback_hold_observability_seam',
    'source_neutral_state_helper_summary_contract_seam',
  ];

  /// Seams that MUST remain at migration/hold/rollback level only.
  /// Tests assert canonical items present.
  static const List<String> kMustRemainAtMigrationHoldRollbackLevel = [
    'db_schema_rewrite',
    'api_endpoint_core_semantics_rewrite',
    'final_fact_settlement_owner_fields',
    'home_page_route_auto_routing_result_fields',
    'review_group_exited_old_path_purge_indicators',
    'active_baseline_declarations',
    'cleanup_bundle_old_path_deletion_markers',
  ];

  /// Conditions that MUST NOT enter active baseline this round.
  /// Tests assert canonical items present.
  static const List<String> kMustNotEnterActiveBaseline = [
    'data_migration_history_refill_compatibility_patch_schema_moves',
    'api_core_purpose_request_return_parameter_semantic_changes',
    'any_field_copy_misleading_ui_br_test_into_thinking_uplift_absorbed',
    'local_serving_stronger_ingest_miswritten_as_final_fact_owner',
    'review_group_runtime_exit_declarations',
  ];

  /// Semantic boundary.
  static const String kSemanticBoundary =
      'uplift_readiness_qualified_to_examine_not_absorbed';

  /// Forbidden claims.
  /// Tests assert canonical forbidden phrases present.
  static const List<String> kForbiddenClaims = [
    'active DB/API baseline 已升级',
    'uplift 已 absorbed',
    '新基线已吸收进运行态',
    '现在已按新契约运行',
    'uplift 已完成',
  ];
}
