/// fuller_cutover_subset_v1 (FROZEN, P3.3.10)
///
/// Expands P3.3.9's `first_cutover_subset_v1` (which was ONLY
/// `reviewpage_non_continuation_serving_subset`) to include the
/// continuity-adjacent serving-adapter family. Still strictly bounded
/// to ReviewPage — home page, active continuation source, final fact
/// owner, and DB/API baselines all remain untouched.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.10-001: P3.3.10 allows fuller cutover to advance only to
///                 ReviewPage continuity-adjacent serving subset,
///                 source-neutral helper contracts, stronger retained-
///                 anchor fallback seams, and stronger ingest candidate
///                 handoff.
///
/// RF-P3.3.10-002: fuller cutover must not cross the
///                 `cutover_vs_fact_owner_boundary_v2`.
///
/// RF-P3.3.10-003: fuller cutover judgment is NOT equivalent to
///                 execution-ready; only grants resource qualification
///                 for next-layer execution judgment, not Room 4
///                 execution order issuance.
library;

/// The 5 layers eligible to join the fuller cutover subset this round.
/// All 5 are strictly bounded to ReviewPage — none touch home page
/// routes, active continuation source, or final fact owner.
enum FullerCutoverLayer {
  /// Layer 1: continuity-adjacent serving-adapter family.
  /// Wider serving-adapter seams that share edges with continuation
  /// logic but do NOT change continuation ownership.
  continuityAdjacentServingAdapter,

  /// Layer 2: source-neutral helper / summary / empty-state /
  /// completion pre-explanation prep.
  sourceNeutralHelperContract,

  /// Layer 3: home page review helper / summary / no-review-state
  /// retained-anchor-aware prep. NOT route switching.
  homePageReviewHelperRetainedAnchorAware,

  /// Layer 4: rollback / hold / fallback neutral copy and state
  /// contract prep.
  rollbackHoldFallbackNeutralPrep,

  /// Layer 5: stronger ingest candidate handoff prep.
  /// Judgment-ready only — not final fact owner switch.
  strongerIngestCandidateHandoff,
}

abstract final class FullerCutoverSubset {
  /// The 5 allowed layers this round (all ReviewPage-bounded).
  /// Tests assert length == 5 and all canonical names present.
  static const List<String> kAllowedLayers = [
    'continuity_adjacent_serving_adapter_family',
    'source_neutral_helper_summary_empty_state_completion_prep',
    'home_page_review_helper_summary_retained_anchor_aware_prep',
    'rollback_hold_fallback_neutral_copy_state_contract_prep',
    'stronger_ingest_candidate_handoff_prep',
  ];

  /// Forbidden expansions (MUST NOT be part of fuller cutover this round).
  /// Tests assert all canonical forbidden items are present.
  static const List<String> kForbiddenExpansions = [
    'home_page_default_route_switch',
    'active_continuation_source_switch',
    'review_group_true_exit',
    'final_fact_owner_shift',
    'active_db_api_baseline_uplift',
    'cleanup_old_path_purge',
    'auto_routing_runtime',
    'unified_planner_planner_merge',
    'user_visible_cutover_completed_announcement',
  ];

  /// Canonical rule: fuller cutover is judgment-ready, NOT execution-ready.
  /// Tests assert this exact string is present.
  static const String kCanonicalRule =
      'fuller_cutover_judgment_not_equivalent_to_execution_ready';

  /// Forbidden user-visible claims about fuller cutover.
  /// Tests assert none of these appear in any visible UI copy.
  static const List<String> kForbiddenClaims = [
    '当前已完成 fuller cutover',
    '新主链路已生效',
    'cutover 已完成',
    '已切到本地规划',
    '本地 serving 已启用',
  ];
}
