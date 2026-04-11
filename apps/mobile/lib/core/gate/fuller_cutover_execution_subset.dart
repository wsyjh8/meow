/// fuller_cutover_execution_subset_v1 (FROZEN, P3.3.11)
///
/// Promotes P3.3.10's `fuller_cutover_subset_v1` from judgment level to
/// execution-ready subset level. Same 5 allowed layer concepts, but now
/// with hardened binding specifications — preflight complete, testable,
/// rollbackable — NOT production-active.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.11-001: expands execution-ready subset to ReviewPage continuity-
///                 adjacent serving-adapter family + source-neutral helpers
///                 + first-page review preparation + rollback/hold contracts.
/// RF-P3.3.11-002: explicitly forbids expansion to home page route switching,
///                 active continuation source switching, planner-aware routing,
///                 review_group true exit, final fact owner shift, active
///                 DB/API baseline uplift absorbed.
/// RF-P3.3.11-003: execution-ready subset indicates readiness for a narrower,
///                 more structured execution layer — it does NOT mean full
///                 cutover execution is complete.
library;

/// The 5 layers eligible to join the execution-ready subset this round.
enum ExecutionReadyLayer {
  /// Layer 1: ReviewPage wider serving-adapter family.
  /// Continuity-adjacent source-selection / adapter / helper / summary /
  /// empty-state / completion. Internal to ReviewPage only.
  reviewPageWiderServingAdapterFamily,

  /// Layer 2: First-page review helper / no-review-state prep.
  /// Retained-anchor-aware prep. NO homepage default route touch.
  firstPageReviewHelperRetainedAnchorAware,

  /// Layer 3: Rollback / hold / fallback neutral contract.
  /// Failure bucket / blast radius / stop-condition definitions.
  /// Rollback target still points to `cloud_review_group_current_runtime_path`.
  rollbackHoldFallbackNeutralContract,

  /// Layer 4: Stronger-ingest candidate execution-ready binding prep.
  /// Accept/reject/duplicate/progress-candidate/completion-candidate more
  /// stable binding — NO final-fact write.
  strongerIngestCandidateExecutionReadyBinding,

  /// Layer 5: Continuity-adjacent helper seam.
  /// Helper / state / guard / observability at active-continuation edge.
  /// NO active continuation true path switch.
  continuityAdjacentHelperSeam,
}

abstract final class FullerCutoverExecutionSubset {
  /// 5 allowed execution-ready layers. Tests assert length == 5 and all
  /// canonical names present.
  static const List<String> kAllowedLayers = [
    'reviewpage_wider_serving_adapter_family_execution_ready',
    'first_page_review_helper_no_review_state_retained_anchor_aware_prep',
    'rollback_hold_fallback_neutral_contract_execution_ready',
    'stronger_ingest_candidate_execution_ready_binding_prep',
    'continuity_adjacent_helper_seam_no_active_continuation_switch',
  ];

  /// Forbidden expansions. Tests assert all canonical forbidden items present.
  static const List<String> kForbiddenExpansions = [
    'home_page_default_route_switch',
    'active_continuation_source_switch',
    'review_group_true_exit',
    'final_fact_owner_shift',
    'active_db_api_baseline_uplift_absorbed',
    'cleanup_old_path_purge',
    'auto_routing_runtime',
    'user_visible_new_main_path_active_claim',
  ];

  /// Semantic boundary: execution-ready = preflight complete, hardened,
  /// testable, rollbackable — NOT production-active.
  static const String kSemanticBoundary =
      'execution_ready_preflight_complete_not_production_active';

  /// Previous stage (P3.3.10 judgment level).
  static const String kPreviousStage = 'p3_3_10_judgment_level';

  /// Current stage (P3.3.11 execution-ready candidate level).
  static const String kCurrentStage =
      'p3_3_11_execution_ready_candidate_level';

  /// Forbidden user-visible claims.
  static const List<String> kForbiddenClaims = [
    '当前已完成 fuller cutover',
    '新主链路已生效',
    'cutover 已完成',
    '已切到本地规划',
    '本地 serving 已启用',
  ];
}
