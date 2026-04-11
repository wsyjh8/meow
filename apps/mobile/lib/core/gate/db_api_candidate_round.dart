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
library;

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
