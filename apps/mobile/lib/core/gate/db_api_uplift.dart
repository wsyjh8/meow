/// db_api_uplift.dart (MERGED in P3.3.14 consolidation round)
///
/// Consolidated DB/API uplift contracts from P3.3.8 through P3.3.14. Active DB/API baselines stay at v0.2.1 throughout. Progression: candidate round (P3.3.8) -> judgment (P3.3.10) -> readiness (P3.3.11) -> absorb-judgment (P3.3.12) -> absorb-readiness (P3.3.13) -> absorb-gate (P3.3.14). Nothing absorbed into active baseline this round.
///
/// This file was consolidated from 6 original per-round files to
/// reduce gate-file sprawl. Class names and constants are preserved
/// exactly so all existing tests continue to work after updating
/// their import paths.
library;

// ============================================================================
// Merged from: db_api_candidate_round.dart
// ============================================================================
/// db_api_candidate_round_v1 (FROZEN, P3.3.8)
///
/// DB/API candidate round boundary — only seam framing, migration
/// markers, rollback floors, hold notes, and write-back order are
/// allowed this round. Schema and endpoint core semantics remain
/// frozen at `v0.2.1`.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.8-004 derivative: DB/API candidate round may only touch seam
///                framing, migration markers, rollback floors, hold notes,
///                and write-back order. Schema and endpoint core
///                semantics remain frozen at v0.2.1.

/// The 5 kinds of work allowed in this DB/API candidate round.
enum DbApiCandidateWorkKind {
  /// Seam candidate: abstract seams between current runtime and future
  /// local-serving. No concrete DB/API commitments.
  seamCandidate,

  /// Migration marker: code-side annotations of future migration
  /// candidates. Not yet executed.
  migrationMarker,

  /// Rollback floor: minimum rollback guarantee template.
  rollbackFloor,

  /// Hold note: conditions that would trigger a Phase 3 hold.
  holdNote,

  /// Write-back order: cross-room document write-back sequence.
  writebackOrder,
}

abstract final class DbApiCandidateRound {
  /// Current active DB baseline. Tests assert this is NOT uplifted.
  static const String kActiveDbBaseline = 'v0.2.1';

  /// Current active API baseline. Tests assert this is NOT uplifted.
  static const String kActiveApiBaseline = 'v0.2.1';

  /// Allowed DB candidate entries (candidate contract level only).
  /// These are semantic NAMES — not schema commitments. Tests assert
  /// the expected canonical names are present.
  static const List<String> kAllowedDbCandidateEntries = [
    'review_queue',
    'learning_stat_daily',
    'user_backup_snapshots',
    'backup_restore_operations',
    'local_planner_queue_candidate_metadata',
    'fact_ingest_candidate_event_markers',
    'migration_rollback_deprecation_markers',
  ];

  /// DB entries that remain current runtime owner/reality (unchanged).
  /// Any reference to `review_groups`, `review_group_items`, or
  /// `review_attempts` in runtime code MUST continue to point at the
  /// current cloud backend without any local override.
  static const List<String> kCurrentRuntimeDbEntries = [
    'review_groups',
    'review_group_items',
    'review_attempts',
    'settlements',
    'reward_ledger',
  ];

  /// API endpoints frozen as current runtime truth this round.
  /// Tests assert these appear in the frozen list verbatim.
  static const List<String> kFrozenApiEndpoints = [
    'GET /me/review-groups/next',
    'POST /review-attempts',
    'GET /me/today',
    'POST /settlements/learning-rounds',
    'GET /settlements/:sourceEventId',
    'POST /me/backup',
    'GET /me/backup/latest',
    'GET /me/backup/latest/snapshot',
  ];

  /// Allowed API seam candidates (candidate contract level, internal only).
  /// These do NOT become public API contracts this round.
  static const List<String> kAllowedApiSeamCandidates = [
    'local_serving_compare_candidate_dto',
    'fact_ingest_candidate_payload_shape',
    'migration_compatibility_metadata',
    'rollback_hold_reason_shape',
    'debug_qa_evidence_envelope',
  ];

  /// Forbidden actions this round.
  /// Any of these would require a Room 1 escalation.
  static const List<String> kForbiddenActions = [
    'schema_rewrite',
    'endpoint_core_semantics_rewrite',
    'active_baseline_uplift',
    'write_candidate_as_current_runtime_truth',
    'change_cloud_first_submit_chain',
    'introduce_user_visible_cutover_mode_api',
    'pass_internal_shadow_candidate_dto_as_public_contract',
  ];
}

// ============================================================================
// Merged from: db_api_uplift_judgment.dart
// ============================================================================
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

// ============================================================================
// Merged from: db_api_uplift_readiness.dart
// ============================================================================
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

// ============================================================================
// Merged from: db_api_uplift_absorb_judgment.dart
// ============================================================================
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

// ============================================================================
// Merged from: db_api_uplift_absorb_readiness.dart
// ============================================================================
/// db_api_uplift_absorb_readiness_v1 (FROZEN, P3.3.13)
///
/// Promotes P3.3.12's `db_api_uplift_absorb_judgment_v1` from
/// absorb-judgment level to absorb-readiness level. "Absorb-readiness"
/// means the patch-draft / seam-map / marker / migration-note /
/// rollback-floor / hold-note for each seam family is ready — it does
/// NOT mean the active baseline has been uplifted absorbed. Active
/// DB/API baselines remain frozen at v0.2.1.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.13-010: only 5 seam families directly bound to the
///                 fuller-cutover execution-subset-v2 + stronger-ingest
///                 absorb-readiness candidate may enter absorb-
///                 readiness.
/// RF-P3.3.13-011: 7 categories must remain at marker / migration /
///                 rollback / hold layer only — no schema rewrite,
///                 no endpoint core semantics rewrite, no active
///                 baseline uplift absorbed.
/// RF-P3.3.13-012: absorb-readiness conclusions stay at readiness
///                 layer only; cannot be elevated to runtime truth.

/// The 5 seam families eligible for uplift-absorb-readiness.
enum UpliftAbsorbReadinessSeamFamily {
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

abstract final class DbApiUpliftAbsorbReadiness {
  /// Uplift status — absorb-readiness qualified, NOT active baseline
  /// uplift absorbed. Tests assert this contains
  /// 'absorb_readiness_qualified_not_active'.
  static const String kStatus =
      'absorb_readiness_qualified_not_active_baseline_uplift_absorbed';

  /// Active DB baseline (unchanged from P3.3.8/9/10/11/12).
  static const String kActiveDbBaselineStillAt = 'v0.2.1';

  /// Active API baseline (unchanged from P3.3.8/9/10/11/12).
  static const String kActiveApiBaselineStillAt = 'v0.2.1';

  /// The 5 seam families eligible for uplift-absorb-readiness.
  /// Tests assert length == 5 and all canonical names.
  static const List<String> kUpliftAbsorbReadinessSeamFamilies = [
    'review_serving_source_descriptor_seam',
    'retained_anchor_fallback_posture_seam',
    'stronger_ingest_path_minimal_seam',
    'rollback_hold_observability_seam',
    'source_neutral_state_helper_summary_contract_seam',
  ];

  /// 7 categories that must remain at marker / migration / rollback /
  /// hold layer (RF-P3.3.13-011). Tests assert all 7 canonical items.
  static const List<String> kMustRemainAtMarkerMigrationRollbackHoldLayer = [
    'review_group_true_exit_seams',
    'active_continuation_source_switch_seams',
    'final_fact_settlement_owner_field_payload_seams',
    'home_page_route_planner_aware_routing_seams',
    'cleanup_old_path_purge_seams',
    'schema_rewrite_history_backfill_compatibility_patch_seams',
    'endpoint_core_semantics_rewrite_seams',
  ];

  /// Semantic boundary: the seam family patch-draft is ready — it does
  /// NOT mean the active baseline has been uplifted.
  static const String kSemanticBoundary =
      'ready_seam_family_patch_draft_not_active_baseline_uplift_complete';

  /// Previous stage (P3.3.12 absorb-judgment level).
  static const String kPreviousStage = 'p3_3_12_absorb_judgment_level';

  /// Current stage (P3.3.13 absorb-readiness level).
  static const String kCurrentStage = 'p3_3_13_absorb_readiness_level';

  /// Forbidden claims (RF-P3.3.13-012).
  static const List<String> kForbiddenClaims = [
    'active DB/API baseline 已升级',
    'uplift 已 absorbed',
    '新基线已吸收进运行态',
    '现在已按新契约运行',
    'uplift 已完成',
    'endpoint meaning 已重写',
    'runtime truth 已同步替换',
    'schema 已重写',
  ];
}

// ============================================================================
// Merged from: db_api_uplift_absorb_gate.dart
// ============================================================================
/// db_api_uplift_absorb_gate_v1 (FROZEN, P3.3.14)
///
/// Promotes P3.3.13's `db_api_uplift_absorb_readiness` from
/// absorb-readiness qualification to **absorb-gate qualification
/// discussion**. Still at judgment layer. Active DB/API baselines
/// remain frozen at `v0.2.1` — nothing is absorbed yet.
///
/// Seam families are split into:
///   - 5 absorbed-gate-ready seam families (advanced to gate level)
///   - 7 marker-only categories (must remain at marker / migration /
///     rollback / hold / observability layer only)
///
/// Only in C may Room 1 authorize absorption into decision-ready.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.14-012: DB/API seams allowed at absorbed judgment — 5
///                 seam families.
/// RF-P3.3.14-013: seams that must stay in marker / migration / hold
///                 layer — 7 categories.
/// RF-P3.3.14-014: uplift-absorbed C-entry conditions — 3 pre-entry
///                 requirements + Room 1 explicit pin.

/// The 5 seam families advanced to absorbed-gate-ready this round.
enum UpliftAbsorbGateSeamFamily {
  /// Seam A: Review serving source descriptor seam, advanced to
  /// absorbed-gate-ready. Still returns cloud `review_group` at runtime.
  reviewServingSourceDescriptorSeam,

  /// Seam B: Retained anchor / fallback posture seam, advanced to
  /// absorbed-gate-ready. 4-role posture persists.
  retainedAnchorFallbackPostureSeam,

  /// Seam C: Stronger-ingest minimal binding seam, advanced to
  /// absorbed-gate-ready. NO final fact write.
  strongerIngestMinimalBindingSeam,

  /// Seam D: Rollback / hold / observability seam, advanced to
  /// absorbed-gate-ready. Rollback target locked.
  rollbackHoldObservabilitySeam,

  /// Seam E: Source-neutral state helper / summary contract seam,
  /// advanced to absorbed-gate-ready. Neutral wording contract.
  sourceNeutralStateHelperSummaryContractSeam,
}

abstract final class DbApiUpliftAbsorbGate {
  /// Current status — absorb-gate qualification discussion, not
  /// active baseline uplift absorbed.
  /// Tests assert this exact string.
  static const String kStatus =
      'uplift_absorb_gate_qualification_discussion_not_active_baseline_uplift_absorbed';

  /// Active DB baseline this round. Tests assert exact equality.
  static const String kActiveDbBaselineStillAt = 'v0.2.1';

  /// Active API baseline this round. Tests assert exact equality.
  static const String kActiveApiBaselineStillAt = 'v0.2.1';

  /// The 5 absorbed-gate-ready seam families (RF-P3.3.14-012).
  /// Tests assert length == 5.
  static const List<String> kAbsorbGateReadySeamFamilies = [
    'review_serving_source_descriptor_seam',
    'retained_anchor_fallback_posture_seam',
    'stronger_ingest_minimal_binding_seam',
    'rollback_hold_observability_seam',
    'source_neutral_state_helper_summary_contract_seam',
  ];

  /// The 7 marker-only categories that MUST remain at marker /
  /// migration / rollback / hold / observability layer only
  /// (RF-P3.3.14-013). Tests assert length == 7.
  static const List<String> kMustRemainAtMarkerMigrationRollbackHoldLayer = [
    'db_schema_rewrite',
    'api_core_semantics_rewrite',
    'fact_ledger_structural_change',
    'settlement_pipeline_structural_change',
    'streak_learning_day_canonical_storage_change',
    'daily_goal_completion_canonical_storage_change',
    'reward_settlement_canonical_storage_change',
  ];

  /// The 3 pre-entry conditions that must hold before Room 1 may
  /// authorize C absorption (RF-P3.3.14-014).
  /// Tests assert length == 3.
  static const List<String> kCAbsorptionPreEntryConditions = [
    'seam_family_readiness_evidence_complete',
    'marker_migration_rollback_hold_note_complete_set',
    'room_1_explicit_pin_for_absorbed_decision',
  ];

  /// Forbidden claims at this level.
  /// Tests assert length == 8.
  static const List<String> kForbiddenClaims = [
    'active_db_api_baseline_already_uplifted',
    'uplift_already_absorbed',
    'schema_already_rewritten',
    'api_core_semantics_already_rewritten',
    'new_baseline_already_in_production',
    'current_running_under_new_contract',
    'absorb_gate_already_opened',
    'absorbed_decision_already_made',
  ];

  /// Semantic boundary: absorb-gate is JUDGMENT layer; baselines
  /// stay at v0.2.1.
  /// Tests assert this contains 'judgment_layer_baselines_stay_v0_2_1'.
  static const String kSemanticBoundary =
      'db_api_uplift_absorb_gate_qualification_remains_judgment_layer_baselines_stay_v0_2_1_'
      'and_does_not_equal_active_baseline_uplift_absorbed';

  /// Previous stage (P3.3.13 absorb-readiness).
  static const String kPreviousStage =
      'p3_3_13_db_api_uplift_absorb_readiness_qualified';

  /// Current stage (P3.3.14 absorb-gate qualification discussion).
  static const String kCurrentStage =
      'p3_3_14_db_api_uplift_absorb_gate_qualification_discussion';
}

