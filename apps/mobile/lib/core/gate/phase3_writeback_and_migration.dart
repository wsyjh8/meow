/// phase3_writeback_and_migration_v1 (FROZEN, P3.3.8)
///
/// Defines the write-back order for cross-room Phase 3 work + the
/// minimum required structure for migration, rollback, and hold notes.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.8-012: write-back order is Room 2 → Room 3 → Room 5 → Room 1
///                → Room 4 (Room 4 only executes after Room 1 formal pin).
/// RF-P3.3.8-013: migration/rollback/hold note minimum requirements:
///                  - migration: before / after / staged conditions / synced docs
///                  - rollback: trigger / target / owner / evidence /
///                    explicit no-cut-runtime-truth statement
///                  - hold: trigger / clearance condition
/// RF-P3.3.8-014: mandatory 3-layer separation
///                (runtime_truth / compatibility_only / deprecated_candidate).
library;

/// The 5 rooms in the cross-room Phase 3 write-back order.
///
/// Each room produces a specific write-back artifact, and they MUST
/// be written in this order. No room may skip ahead until the
/// previous room's work is pinned.
enum WritebackRoom {
  /// Order 1 — Room 2 tech candidate note (DB/API candidate seams).
  r2TechCandidateNote,

  /// Order 2 — Room 3 rules note (gate, hold/escalate, fact-boundary).
  r3RulesNote,

  /// Order 3 — Room 5 UI preflight (forbidden claims, source-neutral).
  r5UiPreflight,

  /// Order 4 — Room 1 absorb / pin (unified absorption).
  r1Absorb,

  /// Order 5 — Room 4 execution (only after Room 1 formal pin).
  r4Execution,
}

/// Contract anchor constants for Phase 3 write-back and migration.
abstract final class Phase3WritebackAndMigration {
  /// Canonical write-back order (5 steps).
  /// Tests assert length == 5 and the exact order.
  static const List<String> kWritebackOrder = [
    'r2_tech_candidate_note',
    'r3_rules_note',
    'r5_ui_preflight',
    'r1_absorb_pin',
    'r4_execution',
  ];

  /// Migration note minimum required fields (RF-P3.3.8-013).
  /// Every Phase 3 migration note must contain all 4 of these.
  static const List<String> kMigrationNoteRequiredFields = [
    'before',
    'after',
    'staged_conditions',
    'synced_docs',
  ];

  /// Rollback note minimum required fields (RF-P3.3.8-013).
  /// The last field is an explicit statement that this round has NOT
  /// cut runtime truth — without it, the rollback note is incomplete.
  static const List<String> kRollbackNoteRequiredFields = [
    'rollback_trigger',
    'rollback_target_return_to_cloud_serving_truth',
    'rollback_owner',
    'rollback_evidence',
    'explicit_no_cut_runtime_truth_statement',
  ];

  /// Hold note minimum required fields (RF-P3.3.8-013).
  static const List<String> kHoldNoteRequiredFields = [
    'hold_trigger',
    'hold_clearance_condition',
  ];

  /// Three-layer separation tags reinforcing P3.3.6 `SemanticLayer`.
  ///
  /// This list intentionally omits 'shadow_only_evidence' because
  /// P3.3.8 write-back docs apply only to the top-3 layers. Shadow
  /// evidence stays in its own lane from P3.3.7 and does not enter
  /// write-back.
  static const List<String> kMandatoryLayerSeparation = [
    'runtime_truth',
    'compatibility_only',
    'deprecated_candidate',
  ];

  /// Explicit statement every P3.3.8 rollback note must carry.
  /// Tests assert this is the exact canonical wording.
  static const String kExplicitNoCutRuntimeTruthStatement =
      'this_round_has_not_cut_runtime_truth';
}
