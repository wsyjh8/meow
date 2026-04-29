/// cutover_subset.dart (MERGED in P3.3.14 consolidation round)
///
/// Consolidated cutover subset contracts from P3.3.8 through P3.3.14. Each rounds cutover subset pins what was allowed at that rounds layer. P3.3.14 RealCutoverExecutionSubset is the first real additive execution subset; earlier rounds sit at judgment/readiness/preflight levels.
///
/// This file was consolidated from 7 original per-round files to
/// reduce gate-file sprawl. Class names and constants are preserved
/// exactly so all existing tests continue to work after updating
/// their import paths.
library;

// ============================================================================
// Merged from: limited_cutover_scope_candidate.dart
// ============================================================================
/// limited_cutover_scope_candidate_v1 (FROZEN, P3.3.8)
///
/// Defines the 5 allowed subsets for a hypothetical future limited
/// cutover. This is a CANDIDATE scope contract — nothing here is
/// executable cutover authorization. Any cutover decision still
/// requires Room 1 pin.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.8-004: minimum viable cutover scope can only be a very narrow
///                subset from the 5 allowed items below.
/// RF-P3.3.8-005: serving source must not shift before fact-settlement
///                boundary is locked.

/// The 5 allowed subsets for a hypothetical future limited cutover.
///
/// A future limited-cutover plan may pick ONE of these as its first
/// target. It MUST NOT pick anything outside this enum.
enum LimitedCutoverScopeItem {
  /// 1. Preparation for a future `review_group` exit.
  /// This round: only prerequisite listing (see ReviewGroupExitGate).
  reviewGroupExitPrep,

  /// 2. Fact ingest stronger-path candidate.
  /// This round: only candidate discussion, NOT active implementation.
  factIngestStrongerPathCandidate,

  /// 3. Helper / summary / state contract migration prep.
  /// This round: source-neutral copy / helper prep only.
  helperSummaryMigrationPrep,

  /// 4. DB/API seam candidate formalization.
  /// This round: candidate contracts only, NOT schema or endpoint rewrite.
  dbApiSeamCandidateFormalization,

  /// 5. Rollback / hold / migration note baseline.
  /// This round: baseline template establishment only.
  rollbackHoldMigrationNoteBaseline,
}

/// Contract anchor constants for limited cutover scope candidate.
abstract final class LimitedCutoverScopeCandidate {
  /// Canonical list of 5 allowed scope items (name strings).
  /// Tests assert length == 5 and all canonical names present.
  static const List<String> kAllowedScopeItemNames = [
    'review_group_exit_prep',
    'fact_ingest_stronger_path_candidate',
    'helper_summary_migration_prep',
    'db_api_seam_candidate_formalization',
    'rollback_hold_migration_note_baseline',
  ];

  /// Layers that are forbidden from entering any cutover scope this round.
  /// None of these are allowed even as candidates.
  static const List<String> kForbiddenCutoverLayers = [
    'reviewpage_local_serving_runtime_cutover',
    'auto_routing_runtime',
    'unified_planner_planner_merge',
    'final_fact_owner_shift',
  ];

  /// The canonical rule: serving source MUST NOT shift before the
  /// fact/settlement boundary is locked. (RF-P3.3.8-005)
  static const String kCanonicalRule =
      'serving_source_must_not_precede_fact_settlement_boundary_lock';

  /// Forbidden user-facing claims about cutover.
  /// Tests assert none of these appear in any visible UI copy.
  static const List<String> kForbiddenClaims = [
    '本地已接管复习',
    '当前复习来自本地队列',
    '已切换到本地复习模式',
    '已切到本地规划',
    '已接管奖励结算',
    '当前已使用新方案',
    '当前已完成兼容切换',
  ];
}

// ============================================================================
// Merged from: first_cutover_subset.dart
// ============================================================================
/// first_cutover_subset_v1 (FROZEN, P3.3.9)
///
/// Contract anchor listing which subset is allowed to enter the first
/// very narrow cutover. Only ONE subset is allowed this round.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.9-001: only ReviewPage internal serving seam's very narrow
///                subset is allowed for first cutover; forbidden:
///                home page runtime switch, active continuation rewrite,
///                review_group exit, final fact owner shift, DB/API
///                baseline uplift.
///
/// RF-P3.3.9-002: first cutover must cut an actual runtime seam, not
///                just helper/copy/state contract changes alone; serving
///                seam is the minimum true cut, not homepage entry.
///
/// RF-P3.3.9-003: first cutover should NOT cut stronger ingest/final-
///                fact path first, but rather very narrow serving seam
///                subset while keeping final fact owner unchanged.
///
/// RF-P3.3.9-004: only allowed runtime-truth switch candidate is
///                ReviewPage internal "where current review items come
///                from" very narrow serving seam.

abstract final class FirstCutoverSubset {
  /// The ONLY allowed first-cutover subset this round.
  /// Tests assert this exact string.
  static const String kOnlyAllowedSubset =
      'reviewpage_non_continuation_serving_subset';

  /// Allowed layers within the subset (RF-P3.3.9-001/002).
  /// Tests assert all 5 canonical layers are present.
  static const List<String> kAllowedLayers = [
    'queue_source_selection_runtime_seam',
    'local_serving_candidate_item_stream_provision',
    'retained_anchor_and_rollback_hooks',
    'observability_floor',
    'source_neutral_helper_summary_empty_state_continuation_copy_neutralization',
  ];

  /// Forbidden subsets — must NOT be part of any first cutover this round.
  /// Tests assert all canonical forbidden subsets are present.
  static const List<String> kForbiddenSubsets = [
    'home_page_runtime_switch',
    'active_continuation_rewrite',
    'review_group_exit',
    'final_fact_owner_shift',
    'db_api_baseline_uplift',
    'full_reviewpage_current_truth_switch',
    'cleanup_bundling',
    'auto_routing_runtime',
  ];

  /// Canonical constraint: first cutover is "runtime seam" not "copy only".
  /// RF-P3.3.9-002 in canonical string form.
  static const String kCanonicalRule =
      'first_cutover_must_cut_actual_runtime_seam_not_just_copy';

  /// Tests assert this is the ONLY subset and that it does not appear
  /// in the forbidden list.
  static bool get isAllowedSubsetNotInForbiddenList =>
      !kForbiddenSubsets.contains(kOnlyAllowedSubset);
}

// ============================================================================
// Merged from: fuller_cutover_subset.dart
// ============================================================================
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

// ============================================================================
// Merged from: fuller_cutover_execution_subset.dart
// ============================================================================
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

// ============================================================================
// Merged from: fuller_cutover_absorb_candidate.dart
// ============================================================================
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

// ============================================================================
// Merged from: fuller_cutover_execution_subset_v2.dart
// ============================================================================
/// fuller_cutover_execution_subset_v2 (FROZEN, P3.3.13)
///
/// Promotes P3.3.12's `fuller_cutover_absorb_candidate_v1` from
/// absorb-candidate judgment level to execution-subset-v2 level. The
/// blast radius remains bounded to ReviewPage + homepage review
/// acceptance layer; execution-subset-v2 is "configured for a more
/// complete execution layer" — it does NOT mean runtime truth has been
/// switched or full cutover has been completed.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.13-001: execution-subset-v2 limited to ReviewPage continuity-
///                 adjacent serving-adapter family + source-neutral
///                 helper/summary/empty-state/completion prefix +
///                 homepage review helper/summary/no-review-state
///                 retained-anchor-aware prep + rollback/hold/fallback
///                 neutral orchestration + stronger-ingest binding
///                 absorb-readiness prep.
/// RF-P3.3.13-002: explicitly forbidden expansions (homepage default
///                 route switch, active continuation source switch,
///                 user-visible planner-aware/auto-routing runtime,
///                 review_group true exit, final fact owner shift,
///                 active DB/API baseline uplift absorbed, cleanup/
///                 old-path purge).
/// RF-P3.3.13-003: blast radius must continue to be primarily limited
///                 to ReviewPage + homepage review acceptance layer.
/// RF-P3.3.13-004: execution-subset-v2 ≠ fuller cutover completed.

/// The 5 layers eligible to join the execution-subset-v2 this round.
enum ExecutionSubsetV2Layer {
  /// Layer A: ReviewPage continuity-adjacent serving-adapter family,
  /// expanded to more-complete execution prep (still internal to
  /// ReviewPage; NO user-visible runtime truth switch).
  reviewPageContinuityAdjacentServingAdapterFamily,

  /// Layer B: Source-neutral helper / summary / empty-state / completion
  /// prefix execution prep. Fuller source-neutral wording coverage
  /// while the truth source explanation stays with cloud `review_group`.
  sourceNeutralHelperSummaryEmptyStateCompletionPrefix,

  /// Layer C: Home page review helper / summary / no-review-state
  /// retained-anchor-aware execution prep. NO homepage default route /
  /// planner-aware / auto-routing runtime changes.
  homePageReviewHelperSummaryNoReviewStateRetainedAnchorAwarePrep,

  /// Layer D: Rollback / hold / fallback neutral orchestration.
  /// Controllable rollback complexity; rollback target remains locked
  /// at `cloud_review_group_current_runtime_path`.
  rollbackHoldFallbackNeutralOrchestration,

  /// Layer E: Stronger-ingest binding absorb-readiness prep.
  /// Execution-preflight binding for stronger ingest — still NO final
  /// fact write and NO final fact owner shift.
  strongerIngestBindingAbsorbReadinessPrep,
}

abstract final class FullerCutoverExecutionSubsetV2 {
  /// 5 allowed execution-subset-v2 layers. Tests assert length == 5.
  static const List<String> kAllowedLayers = [
    'reviewpage_continuity_adjacent_serving_adapter_family',
    'source_neutral_helper_summary_empty_state_completion_prefix',
    'home_page_review_helper_summary_no_review_state_retained_anchor_aware_prep',
    'rollback_hold_fallback_neutral_orchestration',
    'stronger_ingest_binding_absorb_readiness_prep',
  ];

  /// Forbidden expansions — 7 canonical items that MUST NOT be part of
  /// the execution-subset-v2 (RF-P3.3.13-002).
  static const List<String> kForbiddenAdditions = [
    'home_page_default_route_switch',
    'active_continuation_source_switch',
    'user_visible_planner_aware_or_auto_routing_runtime',
    'review_group_true_exit',
    'final_fact_owner_shift',
    'active_db_api_baseline_uplift_absorbed',
    'cleanup_old_path_purge',
  ];

  /// Semantic boundary: execution-subset-v2 is configured for a more
  /// complete execution layer; it does NOT equal runtime truth fully
  /// switched and does NOT equal full cutover completed.
  static const String kSemanticBoundary =
      'execution_subset_configured_for_more_complete_execution_does_not_equal_runtime_truth_fully_switched_or_full_cutover_completed';

  /// Blast radius constraint (RF-P3.3.13-003).
  /// Blast radius continues primarily limited to ReviewPage + homepage
  /// review acceptance layer.
  static const String kBlastRadiusConstraint =
      'blast_radius_continues_primarily_limited_to_reviewpage_plus_home_page_review_acceptance_layer';

  /// Previous stage (P3.3.12 absorb-candidate judgment level).
  static const String kPreviousStage =
      'p3_3_12_absorb_candidate_judgment_level';

  /// Current stage (P3.3.13 execution-subset-v2 level).
  static const String kCurrentStage = 'p3_3_13_execution_subset_v2_level';

  /// Forbidden user-visible claims (12 canonical phrases this round).
  static const List<String> kForbiddenClaims = [
    '本地 serving 已启用',
    'ReviewPage 已切到本地队列',
    'owner shift 已完成',
    'review_group 已退场',
    '当前已完成 fuller cutover',
    '当前已完成 uplift',
    '新主链路已生效',
    '已切到本地规划',
    '新 serving plan 已生效',
    '当前不再使用 review_group',
    'retained anchor 已不再需要',
    '旧路径迁移已完成',
  ];
}

// ============================================================================
// Merged from: real_cutover_execution_subset.dart
// ============================================================================
/// real_cutover_execution_subset_v1 (FROZEN, P3.3.14)
///
/// B-checkpoint execution subset contract. Pins the 5 members that
/// Room 4 is allowed to put into real execution this round, AND pins
/// the 8 items that must NOT enter B execution.
///
/// This is distinct from `fuller_cutover_execution_subset_v2` (P3.3.13),
/// which was an execution-preflight resource qualification at the
/// judgment layer. `real_cutover_execution_subset_v1` authorizes a
/// narrow wave of ACTUAL runtime changes — but narrowly, additively,
/// and under the runtime-truth immovables pinned by
/// `final_cutover_judgment_lock_v1`.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.14-005: B checkpoint allowed execution direction — the 5
///                 members below and only those.
/// RF-P3.3.14-006: B checkpoint forbidden layer — 8 items that must
///                 NOT be swept into B.
/// RF-P3.3.14-007: B checkpoint blast radius — must remain bounded to
///                 ReviewPage + home page review acceptance layer.
/// RF-P3.3.14-008: B checkpoint pass gate — runtime truth regression,
///                 rollback / hold / observability, no-major-change,
///                 no must-hold mismatch, no homepage route / active
///                 continuation / final fact owner touch.

/// The 5 members Room 4 may put into real execution during B.
enum RealCutoverExecutionSubsetMember {
  /// Member 1: ReviewPage continuity-adjacent serving-adapter family.
  /// Advancement from P3.3.13's preflight to a real (but still
  /// cloud-returning) adapter family. Runtime truth for ReviewPage
  /// continues to be cloud `review_group`.
  reviewPageContinuityAdjacentServingAdapterFamily,

  /// Member 2: ReviewPage helper / summary / empty-state / completion
  /// pre-explanation layer. Source-neutral wording goes live; the
  /// explanation layer does not claim any truth-source switch.
  reviewPageHelperSummaryEmptyStateCompletionPreExplanationLayer,

  /// Member 3: Home page review helper / summary / no-review-state
  /// retained-anchor-aware acceptance layer. New wording goes live;
  /// primary home route remains `study_default`; active continuation
  /// acceptance stays independent.
  homePageReviewHelperSummaryNoReviewStateRetainedAnchorAwareLayer,

  /// Member 4: Rollback / hold / fallback neutral orchestration layer.
  /// Neutral copy matrix + fallback state contract go live; rollback
  /// target remains `cloud_review_group_current_runtime_path`.
  rollbackHoldFallbackNeutralOrchestrationLayer,

  /// Member 5: Minimal precondition / binding seam for stronger-ingest
  /// absorb-readiness. Binding semantics in code; NO final fact write,
  /// NO owner shift.
  strongerIngestAbsorbReadinessMinimalBindingSeam,
}

abstract final class RealCutoverExecutionSubset {
  /// Current stage marker — B checkpoint real execution subset pinned.
  /// Tests assert this exact string.
  static const String kStatus =
      'p3_3_14_b_checkpoint_real_cutover_execution_subset_pinned_additively_'
      'not_full_cutover_completed';

  /// The 5 allowed B-checkpoint real execution members.
  /// Tests assert length == 5.
  static const List<String> kAllowedMembers = [
    'review_page_continuity_adjacent_serving_adapter_family',
    'review_page_helper_summary_empty_state_completion_pre_explanation_layer',
    'home_page_review_helper_summary_no_review_state_retained_anchor_aware_layer',
    'rollback_hold_fallback_neutral_orchestration_layer',
    'stronger_ingest_absorb_readiness_minimal_binding_seam',
  ];

  /// The 8 items explicitly forbidden from B execution
  /// (RF-P3.3.14-006). Tests assert length == 8.
  static const List<String> kForbiddenBMembers = [
    'home_page_default_main_route_switch',
    'active_continuation_source_switch',
    'review_group_current_visible_owner_identity_switch',
    'final_fact_and_settlement_owner_switch',
    'db_schema_rewrite',
    'api_core_semantics_rewrite',
    'cleanup_old_path_purge',
    'user_visible_auto_routing_or_planner_aware_route',
  ];

  /// The 5 protection layers that MUST be co-delivered with B
  /// execution — Room 4 cannot ship B members without these.
  /// Tests assert length == 5.
  static const List<String> kCoDeliveredProtectionLayers = [
    'rollback_hold_fallback_neutral_copy_and_state_contract_complete',
    'observability_evidence_capture_in_place',
    'runtime_truth_regression_passes',
    'stop_condition_and_hold_condition_machinery_in_place',
    'user_visible_overclaim_guardrails_in_place',
  ];

  /// B pass-gate conditions (RF-P3.3.14-008). All 5 must hold before
  /// Room 4 may consider B closed and C entry.
  /// Tests assert length == 5.
  static const List<String> kBPassGateConditions = [
    'runtime_truth_regression_passes',
    'rollback_hold_observability_evidence_package_passes',
    'no_major_change_statement_continues_to_hold',
    'no_must_hold_mismatch_remaining_open',
    'no_home_page_route_active_continuation_final_fact_owner_touch',
  ];

  /// Blast radius constraint (RF-P3.3.14-007).
  /// Tests assert this exact string.
  static const String kBlastRadiusConstraint =
      'blast_radius_remains_bounded_to_review_page_and_home_page_review_acceptance_layer';

  /// Semantic boundary: the 5 members are ADDITIVE — they do not
  /// replace, reroute, or dissolve existing runtime truth.
  /// Tests assert this contains 'additive_not_replacement'.
  static const String kSemanticBoundary =
      'real_cutover_execution_subset_v1_is_additive_not_replacement_and_does_'
      'not_equal_full_cutover_or_runtime_owner_shift_or_final_fact_owner_shift';

  /// Previous stage (P3.3.13 execution-subset-v2 preflight level).
  static const String kPreviousStage =
      'p3_3_13_fuller_cutover_execution_subset_v2_preflight_level';

  /// Current stage (P3.3.14 real execution level, additive).
  static const String kCurrentStage =
      'p3_3_14_real_cutover_execution_subset_v1_additive_level';
}

