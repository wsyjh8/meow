/// fuller_cutover_absorb_candidate_v1 (FROZEN, P3.3.12)
///
/// Promotes P3.3.11's `fuller_cutover_execution_subset_v1` from
/// execution-ready candidate to absorb-candidate judgment. Same 5
/// allowed layer concepts, widened scope, but with explicit blast-
/// radius constraint and a semantic boundary that "absorb-candidate"
/// does NOT mean "absorbed into runtime truth".
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.12-001: absorb-candidate judgment subset limited to ReviewPage
///                 continuity-adjacent serving-adapter family +
///                 source-neutral helpers + home page review helpers +
///                 rollback/hold/fallback neutral copy + stronger-ingest
///                 execution-ready binding prep.
/// RF-P3.3.12-002: explicitly forbidden expansions.
/// RF-P3.3.12-003: absorb-candidate judgment ≠ absorbed into runtime truth.
/// RF-P3.3.12-004: blast radius vs rollback complexity must be explicitly
///                 incorporated — impact must stay within ReviewPage +
///                 home page review acceptance layer.
library;

/// The 5 layers eligible to join the absorb-candidate subset this round.
enum AbsorbCandidateLayer {
  /// Layer A: ReviewPage continuity-adjacent serving-adapter family.
  /// Source-selection / adapter / helper / summary / empty-state /
  /// completion foreword explanations, internal to ReviewPage only.
  reviewPageContinuityAdjacentServingAdapterFamily,

  /// Layer B: Home page review helper / summary / no-review-state
  /// retained-anchor-aware judgment. NO homepage default route or
  /// planner-aware/auto-routing.
  homePageReviewHelperSummaryRetainedAnchorAware,

  /// Layer C: Rollback / hold / fallback neutral orchestration.
  /// Controllable rollback complexity and stop-conditions, with
  /// rollback target locked at `cloud_review_group_current_runtime_path`.
  rollbackHoldFallbackNeutralOrchestration,

  /// Layer D: Stronger-ingest binding absorb-candidate prep.
  /// Stabilizes accept/reject/duplicate/progress-candidate/completion-
  /// candidate binding — NO final fact write.
  strongerIngestBindingAbsorbCandidatePrep,

  /// Layer E: Source-neutral state / helper / summary contract family.
  /// UI + helper + state contracts as unified judgment, without
  /// claiming main truth source has switched.
  sourceNeutralStateHelperSummaryContractFamily,
}

abstract final class FullerCutoverAbsorbCandidate {
  /// 5 allowed absorb-candidate layers. Tests assert length == 5.
  static const List<String> kAllowedLayers = [
    'reviewpage_continuity_adjacent_serving_adapter_family',
    'home_page_review_helper_summary_retained_anchor_aware',
    'rollback_hold_fallback_neutral_orchestration',
    'stronger_ingest_binding_absorb_candidate_prep',
    'source_neutral_state_helper_summary_contract_family',
  ];

  /// Forbidden expansions — 7 canonical items that MUST NOT be part of
  /// the absorb-candidate subset.
  static const List<String> kForbiddenAdditions = [
    'home_page_default_route_switch',
    'active_continuation_source_switch',
    'final_fact_owner_shift',
    'review_group_true_exit',
    'active_db_api_baseline_uplift_absorbed',
    'cleanup_old_path_purge',
    'user_visible_mode_switch_announcement',
  ];

  /// Semantic boundary: absorb-candidate judgment is ready to enter the
  /// next layer of fuller-cutover absorb review; it is NOT absorbed into
  /// runtime truth.
  static const String kSemanticBoundary =
      'absorb_candidate_judgment_not_absorbed_into_runtime_truth';

  /// Blast radius constraint (RF-P3.3.12-004).
  /// Widened subset must remain bounded within ReviewPage + homepage
  /// review acceptance layer.
  static const String kBlastRadiusConstraint =
      'widened_subset_must_remain_bounded_within_reviewpage_plus_home_page_review_acceptance_layer';

  /// Previous stage (P3.3.11 execution-ready candidate level).
  static const String kPreviousStage =
      'p3_3_11_execution_ready_candidate_level';

  /// Current stage (P3.3.12 absorb-candidate judgment level).
  static const String kCurrentStage =
      'p3_3_12_absorb_candidate_judgment_level';

  /// Forbidden user-visible claims.
  static const List<String> kForbiddenClaims = [
    '当前已完成 fuller cutover',
    '新主链路已生效',
    'cutover 已完成',
    '已切到本地规划',
    '本地 serving 已启用',
  ];
}
