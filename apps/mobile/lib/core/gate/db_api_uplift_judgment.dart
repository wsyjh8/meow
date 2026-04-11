/// db_api_uplift_judgment_v1 (FROZEN, P3.3.10)
///
/// Defines the 5 seam families eligible for uplift-judgment-ready
/// status. "Uplift-judgment-ready" means "qualified to DISCUSS active
/// baseline uplift" — NOT "active baseline already uplifted".
///
/// Baselines remain at v0.2.1 this round. This file is a pure contract
/// anchor for future rounds to reference.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.10-011: candidate seam, uplift-judgment-ready seam, and
///                 active uplift absorbed must continue layered
///                 separation.
///
/// RF-P3.3.10-012: only seams directly bound to fuller cutover can
///                 advance to uplift-judgment-ready: serving source
///                 descriptor, retained-anchor/fallback posture,
///                 stronger ingest path, rollback/hold/observability,
///                 and source-neutral state/helper/summary contract.
///
/// RF-P3.3.10-013: conclusions (seam sufficiency, rollback floor, helper
///                 contract, stronger ingest seam) can only remain at
///                 judgment layer; must NOT elevate to runtime truth or
///                 active baseline.
library;

/// The 5 seam families eligible for uplift-judgment-ready status.
enum UpliftSeamFamily {
  /// Family 1: review serving source descriptor seam.
  /// Expresses current serving-source judgment without changing endpoint
  /// core semantics.
  reviewServingSourceDescriptorSeam,

  /// Family 2: retained-anchor / fallback posture seam.
  /// Expresses current owner / retained fallback / compatibility /
  /// deprecated candidate posture at marker layer.
  retainedAnchorFallbackPostureSeam,

  /// Family 3: stronger ingest path minimal seam.
  /// Expresses accept/reject/duplicate/progress-candidate/completion-
  /// candidate boundary without equaling final fact write.
  strongerIngestPathMinimalSeam,

  /// Family 4: rollback / hold / observability seam.
  /// Expresses rollback target, hold reason, evidence bucket.
  rollbackHoldObservabilitySeam,

  /// Family 5: continuation-adjacent helper seam.
  /// Continuity-adjacent state/helper/summary/gating boundary.
  /// EXCLUDES active continuation source switch.
  continuationAdjacentHelperSeam,
}

abstract final class DbApiUpliftJudgment {
  /// Uplift status — judgment-ready, NOT active uplift absorbed.
  /// Tests assert this contains 'judgment_ready_not_active'.
  static const String kUpliftStatus =
      'judgment_ready_not_active_baseline_uplift_absorbed';

  /// Active DB baseline — unchanged from P3.3.8.
  /// Tests assert this equals 'v0.2.1'.
  static const String kActiveDbBaselineStillAt = 'v0.2.1';

  /// Active API baseline — unchanged from P3.3.8.
  /// Tests assert this equals 'v0.2.1'.
  static const String kActiveApiBaselineStillAt = 'v0.2.1';

  /// The 5 seam families eligible for uplift judgment.
  /// Tests assert length == 5 and all canonical names present.
  static const List<String> kUpliftJudgmentReadySeamFamilies = [
    'review_serving_source_descriptor_seam',
    'retained_anchor_fallback_posture_seam',
    'stronger_ingest_path_minimal_seam',
    'rollback_hold_observability_seam',
    'continuation_adjacent_helper_seam',
  ];

  /// Forbidden layers for uplift judgment.
  /// Tests assert all canonical forbidden items are present.
  static const List<String> kForbiddenLayers = [
    'db_schema_rewrite',
    'api_endpoint_core_semantics_rewrite',
    'active_baseline_uplift_absorbed',
    'final_fact_settlement_owner_fields_rewrite',
    'home_page_route_auto_routing_fields',
    'review_group_exited_old_path_purge_indicators',
    'new_active_baseline_declarations',
  ];

  /// Conditions required BEFORE active DB/API baseline uplift can occur.
  /// This round only LISTS them — they are NOT checked.
  static const List<String> kRequiredBeforeActiveBaselineUplift = [
    'fuller_subset_has_returnable_runtime_evidence',
    'review_group_exit_gate_conditions_complete',
    'br_ui_db_api_four_piece_synchronized_writeback',
    'no_action_depending_on_db_schema_or_api_core_semantics_change',
    'room_1_separate_execution_judgment_pin_post_uplift',
  ];

  /// Forbidden user-visible claims about uplift.
  /// Tests assert none of these appear in any visible UI copy.
  static const List<String> kForbiddenUpliftClaims = [
    'active DB/API baseline 已升级',
    'uplift 已 absorbed',
    '新基线已吸收进运行态',
    '现在已按新契约运行',
    'uplift 已完成',
  ];
}
