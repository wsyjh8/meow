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
library;

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
