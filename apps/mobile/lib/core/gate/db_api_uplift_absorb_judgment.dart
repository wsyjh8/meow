/// db_api_uplift_absorb_judgment_v1 (FROZEN, P3.3.12)
///
/// Promotes P3.3.11's `db_api_uplift_readiness_v1` from readiness to
/// absorb-judgment. "Absorb-judgment-ready" means "ready to judge
/// absorption qualification" — NOT "active baseline uplift absorbed".
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.12-010: only 5 seam families directly bound to fuller-cutover
///                 widened subset may enter uplift-absorb judgment.
/// RF-P3.3.12-011: 7 categories must remain at marker/migration/rollback/
///                 hold layer.
/// RF-P3.3.12-012: conclusions remain at judgment layer only; cannot be
///                 elevated to runtime truth.
library;

/// The 5 seam families eligible for uplift-absorb judgment.
enum UpliftAbsorbJudgmentSeamFamily {
  /// Family 1: review serving source descriptor seam.
  reviewServingSourceDescriptorSeam,

  /// Family 2: retained-anchor / fallback posture seam.
  retainedAnchorFallbackPostureSeam,

  /// Family 3: stronger-ingest path minimal seam.
  strongerIngestPathMinimalSeam,

  /// Family 4: rollback / hold / observability seam.
  rollbackHoldObservabilitySeam,

  /// Family 5: source-neutral state / helper / summary contract seam.
  sourceNeutralStateHelperSummaryContractSeam,
}

abstract final class DbApiUpliftAbsorbJudgment {
  /// Uplift status — absorb-judgment qualified, NOT absorbed.
  /// Tests assert this contains 'absorb_judgment_qualified_not_active'.
  static const String kStatus =
      'absorb_judgment_qualified_not_active_baseline_uplift_absorbed';

  /// Active DB baseline (unchanged from P3.3.8/9/10/11).
  static const String kActiveDbBaselineStillAt = 'v0.2.1';

  /// Active API baseline (unchanged from P3.3.8/9/10/11).
  static const String kActiveApiBaselineStillAt = 'v0.2.1';

  /// The 5 seam families eligible for uplift-absorb judgment.
  /// Tests assert length == 5 and all canonical names.
  static const List<String> kUpliftAbsorbJudgmentReadySeamFamilies = [
    'review_serving_source_descriptor_seam',
    'retained_anchor_fallback_posture_seam',
    'stronger_ingest_path_minimal_seam',
    'rollback_hold_observability_seam',
    'source_neutral_state_helper_summary_contract_seam',
  ];

  /// 7 categories that must remain at marker/migration/rollback/hold layer
  /// (RF-P3.3.12-011). Tests assert all 7 canonical items present.
  static const List<String> kMustRemainAtMarkerMigrationRollbackHoldLayer = [
    'review_group_true_exit_seams',
    'active_continuation_source_switch_seams',
    'final_fact_settlement_owner_field_payload_seams',
    'home_page_route_planner_aware_routing_seams',
    'cleanup_old_path_purge_seams',
    'schema_rewrite_history_backfill_compatibility_patch_seams',
    'endpoint_core_semantics_rewrite_seams',
  ];

  /// Semantic boundary.
  static const String kSemanticBoundary =
      'ready_to_judge_absorption_qualification_not_active_baseline_uplift_complete';

  /// Forbidden claims.
  static const List<String> kForbiddenClaims = [
    'active DB/API baseline 已升级',
    'uplift 已 absorbed',
    '新基线已吸收进运行态',
    '现在已按新契约运行',
    'uplift 已完成',
    'endpoint meaning 已重写',
    'runtime truth 已同步替换',
  ];
}
