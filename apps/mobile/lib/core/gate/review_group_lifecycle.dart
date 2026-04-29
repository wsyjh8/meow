/// review_group_lifecycle.dart (MERGED in P3.3.14 consolidation round)
///
/// Consolidated review_group posture / exit-gate / exit-candidate / true-exit-gate / true-exit-candidate / true-exit-absorb-gate / transition contracts from P3.3.8 through P3.3.14. review_group continues to hold 4 parallel roles this round (current_runtime_serving_owner + retained_fallback_anchor + compatibility_anchor + deprecated_candidate).
///
/// This file was consolidated from 9 original per-round files to
/// reduce gate-file sprawl. Class names and constants are preserved
/// exactly so all existing tests continue to work after updating
/// their import paths.
library;

// ============================================================================
// Merged from: review_group_retained_anchor.dart
// ============================================================================
/// review_group_retained_anchor_v1 (FROZEN, P3.3.9)
///
/// Extends P3.3.6's `review_group_compatibility_posture_v1` (3-layer)
/// with a 4th role: `retained_fallback_anchor`. This round:
/// `review_group` simultaneously occupies 4 roles.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.9-007: review_group enters dual posture — current runtime
///                owner (for non-cut paths) + retained fallback anchor
///                (for new very narrow seam) + compatibility anchor +
///                deprecated candidate.
///
/// RF-P3.3.9-008: following paths must continue depending on review_group:
///                active continuation identity, current completion gating,
///                current settlement trigger, rollback target, baseline
///                path for non-cutover users/sessions.
///
/// RF-P3.3.9-009: if first-cutover seam triggers stop/hold/rollback,
///                rollback target must be cloud review_group current
///                runtime path.
///
/// RF-P3.3.9-010: forbidden review_group claims — already exited,
///                no longer runtime owner, historical compatibility only,
///                can directly clean old cloud path.

abstract final class ReviewGroupRetainedAnchor {
  /// The 4 roles `review_group` occupies this round.
  /// P3.3.6 defined 3 roles; P3.3.9 adds `retained_fallback_anchor`.
  /// Tests assert this list has exactly 4 entries.
  static const List<String> kFourRoles = [
    'current_runtime_serving_owner',
    'retained_fallback_anchor',
    'compatibility_anchor',
    'deprecated_candidate',
  ];

  /// Canonical 4-role posture status string.
  /// Tests assert all 4 role tags are present in this string.
  static const String kFourRolePostureStatus =
      'runtime_owner_plus_retained_fallback_plus_compatibility_anchor_plus_deprecated_candidate';

  /// Paths that MUST continue depending on `review_group` (RF-P3.3.9-008).
  /// Tests assert all 5 canonical paths are present.
  static const List<String> kPathsStillDependingOnReviewGroup = [
    'active_continuation_identity',
    'current_completion_gating',
    'current_settlement_trigger',
    'rollback_target',
    'baseline_path_for_non_cutover_users_sessions',
  ];

  /// Rollback target — where the seam falls back to when cutover trips.
  /// RF-P3.3.9-009: must be cloud review_group current runtime path.
  static const String kRollbackTarget =
      'cloud_review_group_current_runtime_path';

  /// Forbidden claims (RF-P3.3.9-010).
  /// Tests assert none of these appear in any visible UI copy.
  static const List<String> kForbiddenClaims = [
    'review_group 已退场',
    'review_group 已不再是 runtime owner',
    'review_group 历史兼容 only',
    '可以直接清理旧 cloud path',
    'review_group 已被 local 替代',
  ];
}

// ============================================================================
// Merged from: review_group_exit_gate.dart
// ============================================================================
/// review_group_exit_gate_v1 (FROZEN, P3.3.8)
///
/// Prerequisites for a hypothetical future `review_group` exit. This
/// gate does NOT decide exit — it only lists what must be true before
/// the exit decision can even be discussed.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.8-006: review_group continues as current runtime owner +
///                compatibility anchor + deprecated candidate
///                (not retirement).
/// RF-P3.3.8-007: real exit-gate judgment requires 4 prerequisite
///                categories: contract, test, doc, boundary.
/// RF-P3.3.8-008: approaching prerequisites only enables discussion,
///                NOT immediate retirement.

/// The 4 prerequisite categories for a future `review_group` exit.
///
/// ALL 4 categories must be complete before any exit decision can be
/// discussed. This round only LISTS the prerequisites — it does not
/// check whether they are met.
enum ReviewGroupExitPrerequisiteCategory {
  /// Category A — contract prerequisites (what contracts must be pinned).
  contract,

  /// Category B — test prerequisites (what regression tests must exist).
  test,

  /// Category C — doc prerequisites (what documentation must align).
  doc,

  /// Category D — boundary prerequisites (what boundaries must be clear).
  boundary,
}

abstract final class ReviewGroupExitGate {
  /// Current gate status — prerequisites NOT yet met.
  /// This round: the 4 categories are being listed, not checked.
  /// Tests assert status contains 'prerequisites_not_yet_met'.
  static const String kGateStatus = 'prerequisites_not_yet_met';

  /// Contract prerequisites (category A).
  /// What contracts must be pinned before exit can be discussed.
  static const List<String> kContractPrerequisites = [
    'local_serving_candidate_pinned_as_next_layer_contract',
    'fact_ingest_candidate_pinned',
    'routing_compat_pinned',
    'writeback_markers_pinned',
    'reviewpage_source_neutral_state_contract',
    'continuation_summary_helper_source_neutral_wording_contract',
    'fact_settlement_ingest_boundary_contract',
    'migration_rollback_hold_note_contract',
    'deprecated_vs_compatibility_only_asset_inventory',
  ];

  /// Test prerequisites (category B).
  /// What regression tests must exist and be green.
  static const List<String> kTestPrerequisites = [
    'current_runtime_truth_regression',
    'user_visible_forbidden_claims_regression',
    'shadow_parity_evidence_classification_regression',
    'review_group_still_serving_regression',
    'cutover_candidate_no_leak_regression',
    'no_must_hold_mismatches_unresolved',
  ];

  /// Doc prerequisites (category C).
  /// What documentation must be aligned across BR/UI/DB/API/TEST.
  static const List<String> kDocPrerequisites = [
    'br_exit_gate_conditions',
    'ui_source_neutral_rewrite_migration_path',
    'db_api_candidate_seam_documentation',
    'rollback_hold_note_minimum_template',
    'writeback_order_explicit',
  ];

  /// Boundary prerequisites (category D).
  /// What boundaries must be clear and explicit.
  static const List<String> kBoundaryPrerequisites = [
    'final_fact_settlement_owner_still_clear_backend',
    'no_silent_fact_owner_shift',
  ];

  /// Forbidden "already exited" claims.
  /// Tests assert none of these appear in any UI copy or code comment.
  static const List<String> kForbiddenExitClaims = [
    '已退场',
    '即将退场',
    '已不再使用',
    '可直接清理旧 path',
    '已完成旧方案迁移',
    '当前已不再使用 review_group',
    '旧方案即将不可用',
  ];
}

// ============================================================================
// Merged from: review_group_exit_gate_v2.dart
// ============================================================================
/// review_group_exit_gate_v2 (FROZEN, P3.3.10)
///
/// Extends P3.3.8's `review_group_exit_gate_v1` (4 prerequisite
/// categories) with a new `runtime` category. Total: 5 prerequisite
/// categories must be met before `review_group` exit can even be
/// discussed.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.10-004: review_group continues as current runtime serving
///                 owner + retained fallback anchor + compatibility
///                 anchor + deprecated candidate.
/// RF-P3.3.10-005: review_group can only enter true exit judgment once
///                 5 prerequisite classes are met: contract, test, doc,
///                 runtime, and boundary.
/// RF-P3.3.10-006: transition from retained anchor to exit candidate
///                 must prioritize fallback narrowing before deleting
///                 current owner identity.

/// The 5 prerequisite categories for a future `review_group` exit.
///
/// P3.3.10 adds the `runtime` category to P3.3.8 v1's 4 categories.
enum ExitGateV2PrerequisiteCategory {
  /// Category A — contract prerequisites (extends P3.3.8 v1).
  contract,

  /// Category B — test prerequisites (extends P3.3.8 v1).
  test,

  /// Category C — doc prerequisites (extends P3.3.8 v1).
  doc,

  /// Category D — runtime prerequisites. NEW in P3.3.10.
  /// All 4 runtime paths (active continuation, completion gating,
  /// settlement trigger, rollback target) must have non-ambiguous
  /// replacement paths before exit can be discussed.
  runtime,

  /// Category E — boundary prerequisites (extends P3.3.8 v1).
  boundary,
}

abstract final class ReviewGroupExitGateV2 {
  /// Gate status — v2 prerequisites NOT yet met. This round: the 5
  /// categories are listed as judgment candidates, not checked.
  /// Tests assert status contains 'v2_prerequisites_not_yet_met'.
  static const String kGateStatus =
      'v2_prerequisites_not_yet_met_judgment_candidates_only';

  /// Contract prerequisites (extends P3.3.8 v1).
  /// New in P3.3.10: fuller-cutover subset, fact-owner boundary,
  /// retained-anchor transition, uplift judgment, write-back order.
  static const List<String> kContractPrerequisitesV2 = [
    // NEW in P3.3.10:
    'fuller_cutover_subset_pinned_as_next_layer_contract',
    'cutover_vs_fact_owner_boundary_v2_pinned',
    'retained_anchor_to_exit_transition_pinned',
    'db_api_uplift_judgment_pinned',
    'writeback_order_pinned_for_p3_3_10',
    // P3.3.8 v1 contracts still required:
    'local_serving_candidate_pinned_as_next_layer_contract',
    'fact_ingest_candidate_pinned',
    'routing_compat_pinned',
    'writeback_markers_pinned',
  ];

  /// Test prerequisites (extends P3.3.8 v1).
  static const List<String> kTestPrerequisitesV2 = [
    // NEW in P3.3.10:
    'continuity_adjacent_subset_regression_long_term_stable',
    'continuity_adjacent_rollback_hold_observability_stable',
    'no_must_hold_mismatches_uncleaned',
    // P3.3.8 v1 tests still required:
    'current_runtime_truth_regression',
    'shadow_parity_evidence_classification_regression',
    'review_group_still_serving_regression',
  ];

  /// Doc prerequisites (extends P3.3.8 v1).
  /// New in P3.3.10: four-piece (BR/UI/DB/API) synchronization.
  static const List<String> kDocPrerequisitesV2 = [
    // NEW in P3.3.10:
    'br_ui_db_api_test_exit_impact_scope_synchronized',
    'rollback_target_hold_note_no_overclaim_copy_synchronized',
    // P3.3.8 v1 docs still required:
    'br_exit_gate_conditions',
    'writeback_order_explicit',
  ];

  /// NEW runtime prerequisites (P3.3.10 only).
  /// All 4 paths must have non-ambiguous replacement paths before exit
  /// can be discussed.
  static const List<String> kRuntimePrerequisitesNewInV2 = [
    'active_continuation_unambiguous_replacement_path',
    'completion_gating_unambiguous_replacement_path',
    'settlement_trigger_unambiguous_replacement_path',
    'rollback_target_still_returnable_repeatable_verifiable',
  ];

  /// Boundary prerequisites (extends P3.3.8 v1).
  static const List<String> kBoundaryPrerequisitesV2 = [
    'final_fact_settlement_owner_still_clear_backend',
    'no_silent_fact_owner_shift',
  ];

  /// Forbidden claims (extends P3.3.8 v1 + P3.3.9's retained-anchor list).
  /// Tests assert none of these appear in any visible UI copy.
  static const List<String> kForbiddenClaims = [
    'review_group 已退场',
    '已不再使用 review_group',
    'review_group 可直接清理',
    'retained anchor 已不再需要',
    'review_group 已变成 fallback-only',
    '旧 cloud path 可回收',
  ];
}

// ============================================================================
// Merged from: review_group_exit_candidate.dart
// ============================================================================
/// review_group_exit_candidate_v1 (FROZEN, P3.3.11)
///
/// Promotes P3.3.10's `review_group_exit_gate_v2` from gate-prerequisite
/// listing to exit-candidate qualified status. "Exit-candidate" means
/// "retirement-qualification preparation stage" — NOT "true exit",
/// NOT "currently safe to exit".
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.11-004: review_group must maintain 4 concurrent layers:
///                 current runtime serving owner, retained fallback anchor,
///                 compatibility anchor, and deprecated candidate.
/// RF-P3.3.11-005: exit-candidate layer permits only 5 allowed classes
///                 (dependency inventory / replacement-readiness markers /
///                 retained-anchor → exit-candidate conditions / fallback
///                 scope judgment / no-overclaim assertions).
/// RF-P3.3.11-006: paths that MUST continue depending on review_group:
///                 active continuation identity, completion gating,
///                 settlement trigger, rollback target, baseline compare,
///                 widened-subset failure fallback, user-visible main
///                 queue ultimate fallback.

/// The 5 allowed classes of work in the exit-candidate layer.
enum ExitCandidateClass {
  /// Class 1: dependency inventory — explicit listing of paths still
  /// dependent on review_group.
  dependencyInventory,

  /// Class 2: replacement-readiness marker — whether replacement path
  /// exists, is verifiable, is explainable. Marker ≠ active replacement.
  replacementReadinessMarker,

  /// Class 3: retained-anchor → exit-candidate conditions — hardened
  /// conditions for when anchor can be narrowed (contract / test / doc /
  /// runtime evidence / boundary guard).
  retainedAnchorToExitCandidateConditions,

  /// Class 4: fallback scope judgment — which rollback/fallback scopes
  /// may eventually narrow very narrowly.
  fallbackScopeJudgment,

  /// Class 5: no-overclaim / no-cleanup assertions — must explicitly
  /// state current-and-not-retired/removed/purged.
  noOverclaimNoCleanupAssertions,
}

abstract final class ReviewGroupExitCandidate {
  /// Current status — exit-candidate qualified, NOT true exit.
  /// Tests assert this contains 'exit_candidate_qualified_not_true_exit'.
  static const String kStatus =
      'exit_candidate_qualified_not_true_exit_not_safe_to_exit';

  /// The 4-layer posture that MUST continue (same as P3.3.9 retained-anchor).
  /// Tests assert length == 4 and all canonical roles present.
  static const List<String> kFourLayersMustContinue = [
    'current_runtime_serving_owner',
    'retained_fallback_anchor',
    'compatibility_anchor',
    'deprecated_candidate',
  ];

  /// Paths that MUST continue depending on review_group.
  /// Tests assert length == 7 and all canonical paths present.
  static const List<String> kPathsStillDependingOnReviewGroup = [
    'active_continuation_identity',
    'current_completion_gating',
    'current_settlement_trigger',
    'rollback_target',
    'baseline_compare_compatibility_anchor',
    'widened_subset_failure_fallback_path',
    'user_visible_main_queue_ultimate_fallback',
  ];

  /// Forbidden claims (extends P3.3.10 v2).
  /// Tests assert canonical forbidden phrases present.
  static const List<String> kForbiddenClaims = [
    'review_group 已退场',
    '已不再使用 review_group',
    'review_group 可直接清理',
    'review_group 已变成 fallback-only',
    '旧 cloud path 可回收',
    'true exit 已开始',
    '现在已经可以清理旧 path',
    'retained anchor 已不再需要',
  ];
}

// ============================================================================
// Merged from: review_group_true_exit_gate.dart
// ============================================================================
/// review_group_true_exit_gate_v1 (FROZEN, P3.3.12)
///
/// Extends P3.3.11's `review_group_exit_candidate_v1` from exit-candidate
/// qualified status to true-exit-gate JUDGMENT status. Key distinction:
/// this is JUDGMENT about qualification to discuss entering the true-exit
/// gate — NOT the initiation of actual true exit.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.12-005: review_group must maintain 4 concurrent layers.
/// RF-P3.3.12-006: 5 condition categories must be met before true-exit
///                 judgment: contract / runtime / test / doc / fallback.
/// RF-P3.3.12-007: 6 still-dependent paths block true exit.
/// RF-P3.3.12-008: true-exit-gate judgment ≠ true exit has begun.

abstract final class ReviewGroupTrueExitGate {
  /// Current status — true-exit-gate qualification discussion, NOT
  /// true exit started.
  /// Tests assert this contains 'true_exit_gate_qualification_discussion'.
  static const String kStatus =
      'true_exit_gate_qualification_discussion_not_true_exit_started';

  /// The 4-layer posture that MUST continue (same as P3.3.9 4-role).
  /// Tests assert length == 4.
  static const List<String> kFourLayersMustContinue = [
    'current_runtime_serving_owner',
    'retained_fallback_anchor',
    'compatibility_anchor',
    'deprecated_candidate',
  ];

  /// 6 still-dependent paths that block review_group from true exit
  /// (RF-P3.3.12-007). Tests assert length == 6 and all canonical items.
  static const List<String> kSixStillDependentPaths = [
    'active_continuation_identity',
    'completion_gating',
    'settlement_trigger',
    'rollback_target',
    'non_cutover_non_upgraded_sessions_baseline_path',
    'compatibility_anchor_qa_baseline_reference',
  ];

  /// 7 missing preconditions (RF-P3.3.12-006).
  /// Tests assert length == 7 and all canonical items.
  static const List<String> kSevenMissingPreconditions = [
    'replacement_path_completeness',
    'active_continuation_independence',
    'completion_settlement_trigger_decoupling',
    'rollback_target_replacement_readiness',
    'compatibility_anchor_retirement_readiness',
    'non_cutover_baseline_path_safety',
    'documentation_test_runtime_evidence_completeness',
  ];

  /// Semantic boundary.
  static const String kSemanticBoundary =
      'ready_to_discuss_true_exit_gate_qualification_not_true_exit_started_or_completed';

  /// Forbidden claims.
  /// Tests assert canonical forbidden phrases present.
  static const List<String> kForbiddenClaims = [
    'review_group 已退场',
    '已不再使用 review_group',
    'review_group 可直接清理',
    'review_group 已变成 fallback-only',
    'retained anchor 已不再需要',
    'rollback target 已变',
    '旧 cloud path 可回收',
    'true exit 已开始',
  ];
}

// ============================================================================
// Merged from: review_group_true_exit_candidate.dart
// ============================================================================
/// review_group_true_exit_candidate_v1 (FROZEN, P3.3.13)
///
/// Promotes P3.3.12's `review_group_true_exit_gate_v1` from
/// true-exit-gate judgment level to true-exit-candidate level. This is
/// candidate-artifact status: the qualification conditions for the
/// true-exit gate are now assembled into a candidate profile, but
/// actual true exit has NOT begun. `review_group` still simultaneously
/// holds all 4 roles this round.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.13-005: `review_group` must continue to simultaneously hold
///                 current runtime serving owner, retained fallback
///                 anchor, compatibility anchor, and deprecated
///                 candidate roles.
/// RF-P3.3.13-006: conditions allowed to enter true-exit-candidate.
/// RF-P3.3.13-007: 6 paths still dependent on `review_group` this
///                 round — none may be decoupled yet.
/// RF-P3.3.13-008: true-exit-candidate = candidate artifacts, NOT
///                 true exit started / completed / fallback-only.
/// RF-P3.3.13-009: true-exit-candidate ≠ true exit started.

abstract final class ReviewGroupTrueExitCandidate {
  /// Current status — true-exit-candidate qualified, NOT true exit
  /// started. Tests assert this contains
  /// 'true_exit_candidate_qualified_not_true_exit_started'.
  static const String kStatus =
      'true_exit_candidate_qualified_not_true_exit_started';

  /// The 4-layer posture that `review_group` MUST continue to hold
  /// this round (same as P3.3.9 4-role + P3.3.12 4-layer).
  /// Tests assert length == 4.
  static const List<String> kFourLayersMustContinue = [
    'current_runtime_serving_owner',
    'retained_fallback_anchor',
    'compatibility_anchor',
    'deprecated_candidate',
  ];

  /// 6 still-dependent paths that block `review_group` from true exit
  /// (RF-P3.3.13-007). Tests assert length == 6 and all canonical items.
  static const List<String> kSixStillDependentPaths = [
    'active_continuation_identity',
    'completion_gating',
    'settlement_trigger',
    'rollback_target',
    'non_cutover_non_upgraded_sessions_baseline_path',
    'compatibility_anchor_qa_baseline_reference',
  ];

  /// 7 still-missing preconditions — inherited from P3.3.12 true-exit-
  /// gate and framed here for true-exit-candidate evaluation. None of
  /// these are simultaneously satisfied this round.
  /// Tests assert length == 7 and all canonical items.
  static const List<String> kSevenStillMissingPreconditions = [
    'replacement_path_completeness',
    'active_continuation_independence',
    'completion_settlement_trigger_decoupling',
    'rollback_target_replacement_readiness',
    'compatibility_anchor_retirement_readiness',
    'non_cutover_baseline_path_safety',
    'documentation_test_runtime_evidence_completeness',
  ];

  /// Semantic boundary: true-exit-candidate means candidate artifacts
  /// are assembled — it does NOT mean true exit has started, is
  /// fallback-only, or is already completed.
  static const String kSemanticBoundary =
      'true_exit_candidate_qualification_artifacts_not_true_exit_started_or_completed';

  /// Previous stage (P3.3.12 true-exit-gate judgment level).
  static const String kPreviousStage =
      'p3_3_12_true_exit_gate_judgment_level';

  /// Current stage (P3.3.13 true-exit-candidate level).
  static const String kCurrentStage = 'p3_3_13_true_exit_candidate_level';

  /// Forbidden claims this round (RF-P3.3.13-008).
  /// Tests assert canonical forbidden phrases present.
  static const List<String> kForbiddenClaims = [
    'review_group 已退场',
    '已不再使用 review_group',
    'review_group 可直接清理',
    'review_group 已变成 fallback-only',
    'retained anchor 已不再需要',
    'rollback target 已变',
    '旧 cloud path 可回收',
    'true exit 已开始',
  ];
}

// ============================================================================
// Merged from: review_group_true_exit_absorb_gate.dart
// ============================================================================
/// true_exit_absorb_gate_v1 (FROZEN, P3.3.14)
///
/// Promotes P3.3.13's `review_group_true_exit_candidate` from
/// candidate qualification to **absorb-gate qualification discussion**.
/// This is the layer that sits between "true exit is a candidate" and
/// "true exit has actually been absorbed as runtime truth" — it is
/// still at the JUDGMENT/gate discussion level, not a switch.
///
/// `review_group` continues to hold all 4 parallel roles simultaneously:
///   - current_runtime_serving_owner
///   - retained_fallback_anchor
///   - compatibility_anchor
///   - deprecated_candidate
///
/// Only in C (cleanup closeout) — and only if all absorb-gate entry
/// conditions hold — may Room 1 authorize absorption as true exit.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.14-009: `review_group` 4-role parallel state requirement
///                 remains in effect.
/// RF-P3.3.14-010: true-exit-absorb-gate entry conditions — 7
///                 preconditions.
/// RF-P3.3.14-011: stop-at-B conditions for true-exit-absorb — if any
///                 fire, Room 4 stops at B and does NOT enter C.

abstract final class ReviewGroupTrueExitAbsorbGate {
  /// Current status — gate qualification discussion, not started.
  /// Tests assert this exact string.
  static const String kStatus =
      'true_exit_absorb_gate_qualification_discussion_not_absorption_started';

  /// The 4 roles `review_group` continues to hold in parallel this
  /// round. Tests assert length == 4 and exact membership.
  static const List<String> kFourRolesMustContinue = [
    'current_runtime_serving_owner',
    'retained_fallback_anchor',
    'compatibility_anchor',
    'deprecated_candidate',
  ];

  /// The 6 still-dependent paths (same set as
  /// FinalCutoverJudgmentLock.kStillDependentPaths but listed here
  /// in the absorb-gate context).
  /// Tests assert length == 6.
  static const List<String> kSixStillDependentPaths = [
    'active_continuation_identity',
    'completion_gating',
    'settlement_trigger',
    'rollback_target',
    'non_cutover_non_upgraded_sessions_baseline_path',
    'compatibility_anchor_qa_baseline_reference',
  ];

  /// The 7 absorb-gate entry conditions (RF-P3.3.14-010). All must
  /// hold before Room 1 may authorize true-exit absorption in C.
  /// Tests assert length == 7.
  static const List<String> kSevenAbsorbGateEntryConditions = [
    'active_continuation_has_stable_replacement_path',
    'completion_gating_has_clear_replacement_path',
    'settlement_trigger_has_clear_replacement_path',
    'rollback_target_has_future_safe_replacement_proof',
    'non_cutover_non_upgraded_sessions_baseline_path_has_alternative_explanation',
    'compatibility_anchor_qa_baseline_reference_can_be_migrated',
    'br_ui_db_api_test_exit_impact_scope_already_synchronized',
  ];

  /// The 7 stop-at-B conditions (RF-P3.3.14-011). If any of these
  /// fire, Room 4 stops at B and does NOT enter C.
  /// Tests assert length == 7.
  static const List<String> kSevenStopAtBConditions = [
    'current_runtime_truth_silently_altered',
    'active_continuation_switched_to_local_path',
    'review_group_true_exit_evidence_incomplete',
    'absorb_evidence_incomplete',
    'final_fact_owner_boundary_broken',
    'rollback_hold_fallback_copy_incomplete',
    'user_side_overclaim_of_exited_or_absorbed_or_cleaned_up',
  ];

  /// Forbidden claims at this level — Room 4 must not express any
  /// of these via code, copy, or tests.
  /// Tests assert length == 8.
  static const List<String> kForbiddenClaims = [
    'review_group_already_exited',
    'review_group_true_exit_started',
    'review_group_absorbed_as_historical',
    'retained_anchor_no_longer_needed',
    'rollback_target_has_changed',
    'current_serving_truth_already_switched_from_cloud',
    'old_path_cleanup_completed',
    'compatibility_anchor_already_removed',
  ];

  /// Semantic boundary: absorb-gate qualification is JUDGMENT layer,
  /// not an execution flip.
  /// Tests assert this contains 'judgment_layer_not_execution_flip'.
  static const String kSemanticBoundary =
      'true_exit_absorb_gate_qualification_remains_judgment_layer_not_execution_flip_'
      'and_does_not_equal_true_exit_started_or_true_exit_absorbed';

  /// Previous stage (P3.3.13 true-exit-candidate).
  static const String kPreviousStage =
      'p3_3_13_review_group_true_exit_candidate_qualified';

  /// Current stage (P3.3.14 absorb-gate qualification discussion).
  static const String kCurrentStage =
      'p3_3_14_true_exit_absorb_gate_qualification_discussion';
}

// ============================================================================
// Merged from: retained_anchor_to_exit_transition.dart
// ============================================================================
/// retained_anchor_to_exit_transition_v1 (FROZEN, P3.3.10)
///
/// Defines the classification between "still-fixed" rollback/anchor
/// items and "future-narrowable" items, plus the canonical ordering
/// rule for any future transition from retained-anchor to exit-candidate.
///
/// ============================================================================
/// Canonical ordering rule
/// ============================================================================
///
///   Replace → Then narrow
///
/// (NEVER narrow → then supplement)
///
/// The dependency paths that currently rely on `review_group` must
/// first be given explicit replacement contracts. Only AFTER that can
/// any fallback/rollback scope be narrowed.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.10-006: transition must prioritize fallback narrowing before
///                 deleting current owner identity.
/// RF-P3.3.10-007: certain paths must continue explicitly depending on
///                 review_group.
/// RF-P3.3.10-014: rollback target must continue pointing to cloud
///                 review_group current runtime path.
/// RF-P3.3.10-015: fallback/rollback can only narrow after retained-
///                 anchor dependency paths are step-by-step replaced.

abstract final class RetainedAnchorToExitTransition {
  /// Canonical ordering rule.
  /// Tests assert this contains 'replace_first_then_narrow'.
  static const String kCanonicalOrderingRule =
      'replace_first_then_narrow_never_narrow_first_then_supplement';

  /// Canonical rollback target — MUST stay at cloud review_group.
  /// Tests assert this equals the canonical P3.3.9 rollback target.
  static const String kStillFixedRollbackTarget =
      'cloud_review_group_current_runtime_path';

  /// Items that MUST remain fixed this round (cannot be narrowed).
  /// Tests assert length == 8 and all canonical items are present.
  static const List<String> kStillFixed = [
    'rollback_target_cloud_review_group_current_runtime_path',
    'current_owner_identity_not_downgradable_to_fallback_only',
    'compatibility_anchor_unchanged',
    'deprecated_candidate_marker_unchanged',
    'active_continuation_identity_unchanged',
    'completion_gating_current_review_group_dependency',
    'settlement_trigger_current_review_group_dependency',
    'non_cutover_baseline_path_current_review_group_fallback',
  ];

  /// Items that MAY become narrowable in the FUTURE (not this round).
  /// P3.3.10 only lists these as candidates for future judgment.
  /// Tests assert length == 5 and all canonical candidates are present.
  static const List<String> kFutureNarrowable = [
    'fallback_rollback_scope_only_after_replacement_paths_complete',
    'which_widened_subset_failure_must_return_to_primary_target',
    'which_paths_can_be_separated_from_review_group_dependency',
    'retained_anchor_responsibilities_narrowing_toward_exit_candidate',
    'secondary_fallback_routing_granularity_distinction',
  ];

  /// Preconditions required BEFORE any fallback/rollback narrowing
  /// can be discussed. Tests assert all 5 canonical preconditions.
  static const List<String> kPreconditionsBeforeNarrowing = [
    'active_continuation_replacement_contract_explicitly_declared',
    'completion_gating_replacement_contract_explicitly_declared',
    'settlement_trigger_replacement_contract_explicitly_declared',
    'non_cutover_baseline_path_explicitly_declared',
    'rollback_still_has_usable_target',
  ];

  /// Stop-conditions that MUST trigger hold if any appear.
  /// Tests assert canonical stop triggers are present.
  static const List<String> kStopConditions = [
    'active_continuation_silent_reroute_to_local_path',
    'local_subset_written_as_current_reviewpage_full_truth',
    'local_evidence_directly_modifying_final_ledger_daily_goal_streak_settlement',
    'home_page_route_planner_aware_auto_routing_rewrite',
    'user_visible_cutover_completed_owner_shift_review_group_exited_overclaim',
    'db_schema_api_core_semantics_change_requirement',
    'rollback_path_nonexistent_unverifiable_unexplainable',
  ];

  /// Canonical meaning: P3.3.10 only DEFINES when qualified for true
  /// exit candidate transition; NOT "now transition".
  /// Tests assert this contains 'not_now_transition'.
  static const String kCanonicalMeaning =
      'p3_3_10_only_defines_when_qualified_for_true_exit_candidate_transition_not_now_transition';
}

// ============================================================================
// Merged from: exit_candidate_to_true_exit_transition.dart
// ============================================================================
/// exit_candidate_to_true_exit_transition_v1 (FROZEN, P3.3.12)
///
/// NEW contract this round. Defines the simultaneous preconditions that
/// must hold before any transition from exit-candidate to true-exit-gate
/// can even be DISCUSSED. This is NOT transition execution.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.12-009: retained anchor narrowing only future-discussable if
///                 rollback target has verifiable replacement, active
///                 continuation has stable contract, completion/settlement
///                 gating has non-group-dependent pathways, and
///                 no-overclaim boundaries are synchronized.
/// RF-P3.3.12-016: 5 items must remain fixed (immobile).
/// RF-P3.3.12-017: 4 future-discussable items.
///
/// ============================================================================
/// Canonical rule
/// ============================================================================
///
///   Discussable transition CONDITIONS, not transition execution.
///
/// Current phase only permits discussing the SEVEN simultaneous
/// preconditions; current phase does NOT permit any transition
/// execution itself.

abstract final class ExitCandidateToTrueExitTransition {
  /// Current status — transition conditions discussable, NOT execution.
  /// Tests assert this contains
  /// 'transition_conditions_discussable_not_transition_execution'.
  static const String kStatus =
      'transition_conditions_discussable_not_transition_execution';

  /// 5 items that MUST remain fixed (immobile) this round.
  /// Tests assert length == 5 and all canonical items.
  static const List<String> kFiveImmobileItems = [
    'rollback_target_cloud_review_group_current_runtime_path',
    'current_visible_owner_identity',
    'retained_fallback_anchor_identity',
    'active_continuation_current_path',
    'completion_gating_settlement_trigger_explanation_pathway',
  ];

  /// 7 simultaneous preconditions (all must be concurrently satisfied).
  /// Tests assert length == 7 and all canonical items.
  static const List<String> kSevenSimultaneousPreconditions = [
    'current_owner_explanation_pathway_has_replacement_plan',
    'active_continuation_remains_independent_or_separate_migration',
    'rollback_target_future_replaceable_proof',
    'completion_gating_settlement_trigger_alternative_explanation_pathway',
    'compatibility_anchor_baseline_compare_path_can_migrate',
    'no_cleanup_assertions_remain_valid',
    'regression_runtime_evidence_documentation_readiness_complete_as_suite',
  ];

  /// 4 items that may only be FUTURE-discussed (not this round).
  /// Tests assert length == 4 and canonical items.
  static const List<String> kFutureDiscussableItems = [
    'when_rollback_target_might_become_changeable',
    'when_fallback_scope_might_become_narrower',
    'when_review_group_might_transition_from_current_owner_plus_retained_anchor_posture',
    'which_docs_qa_ui_copy_must_first_decouple_from_group_only_dependency',
  ];

  /// 4 rollback target / fallback scope change conditions (all must coexist).
  /// Tests assert length == 4 and canonical items.
  static const List<String> kRollbackTargetChangeConditions = [
    'replacement_path_has_runtime_evidence',
    'stop_condition_rollback_path_can_be_explained',
    'non_cutover_baseline_path_no_longer_depends_on_current_target',
    'room_1_separately_pins_true_exit_gate_next_round_execution',
  ];

  /// Canonical rule.
  /// Tests assert this contains
  /// 'discussable_transition_conditions_not_transition_execution'.
  static const String kCanonicalRule =
      'discussable_transition_conditions_not_transition_execution_commencing_now';
}

