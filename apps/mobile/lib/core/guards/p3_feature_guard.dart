/// P3 Feature Guard — Phase 0 safety layer.
///
/// All flags default to false. A flag must only be set to true
/// when Room 1 has pinned the corresponding contract as active baseline.
///
/// This is NOT a feature-flag system for users. It is an engineering
/// guardrail to prevent accidental route/render/data-consumption
/// for unpinned P3 candidate contracts.
abstract final class P3FeatureGuard {
  /// Statistics independent page (route + navigation + shell).
  /// Phase 0 guard — do not enable without Room 1 pin.
  static const bool isStatisticsPageEnabled = false;

  /// CTA decision-support block (today_primary_action or equivalent).
  /// Phase 0 guard — do not enable without Room 1 pin.
  static const bool isCTADecisionSupportEnabled = false;

  /// Streak basis switch (learning_day-based streak).
  /// Phase 0 guard — do not enable without Room 1 pin.
  static const bool isStreakBasisSwitchEnabled = false;

  /// Review readiness contract (deeper review_summary / readiness).
  /// Phase 0 guard — do not enable without Room 1 pin.
  static const bool isReviewReadinessContractEnabled = false;

  /// Streak future explanation block (e.g., "rules may change" notice).
  /// Phase 4 guard — do not enable without Room 1 pin of future explanation contract.
  /// When false: no explanation about future streak policy is shown anywhere.
  static const bool isStreakExplanationEnabled = false;

  // ==================== P3.1 — Local Progress + Cloud Backup ====================
  //
  // P3.2 BACKUP CUTOVER — flags flipped true.
  // card_states (FSRS scheduling) now included in snapshots (schema p3_2_snapshot_v1).
  // Device model + device_id added to backup metadata.
  // Auto-backup on app background + post-review-session (>30min interval).
  // Multi-device conflict policy: last-write-wins.

  /// P3.1 — Local snapshot export.
  /// P3.2: ENABLED — includes card_states (FSRS) + device metadata.
  static const bool isLocalBackupEnabled = true;

  /// P3.1 — Cloud backup upload.
  /// P3.2: ENABLED — cloud is backup container, NOT sync endpoint.
  /// Note: upload success != sync success.
  static const bool isCloudBackupEnabled = true;

  /// P3.1 — Restore from backup.
  /// Phase 4: enabled. Restore is gated with pre-check + confirmation dialog.
  static const bool isRestoreEnabled = true;

  /// P3.1 — Backup settings entry (settings/my page visibility).
  /// P3.2: ENABLED — backup section visible in settings page.
  static const bool isBackupSettingsEntryEnabled = true;

  // ==================== P3.1 Delta — Download / Manual Upload / Daily Goal ====================

  /// P3.1 Delta Phase 1 — Daily goal setting UI in settings page.
  /// Enabled: user can change daily word count in settings.
  static const bool isDailyGoalSettingEnabled = true;

  /// P3.1 Delta Phase 2 — Manual upload (user-initiated upload progress to cloud).
  /// Enabled: upload button in settings page is functional.
  static const bool isManualUploadEnabled = true;

  /// P3.1 Delta Phase 3 — Download cloud progress to local device.
  /// Enabled: download/restore in settings page is functional.
  static const bool isDownloadToLocalEnabled = true;

  // ==================== P3.3.5 — Shadow-Prep Flags (DISABLED) ====================
  //
  // planner_owner_shift_v2 + review_serving_contract_v2 shadow-prep.
  // These flags are PHASE 0 GUARDS — they prepare the code seams for a
  // future local planner owner shift, but they MUST remain false in this
  // round. Enabling any of them without a Room 1 pin is an Out-of-Scope
  // escalation trigger (see CLAUDE.md §4).
  //
  // RF-P3.3.5-001: local primary planner owner is only a future target-
  //                state candidate — NOT current runtime truth.
  // RF-P3.3.5-004: ReviewPage current serving truth MUST NOT be silently
  //                cut over.
  // RF-P3.3.5-016: deprecated MUST NOT be written as active truth.

  /// P3.3.5 — Future local planner owner shift shadow-prep.
  /// When true (NOT this round): would enable a shadow path for a
  /// local-serving queue candidate. Never exposed to users in this round.
  /// Current runtime MUST use cloud `review_group` regardless.
  static const bool isLocalPlannerOwnerShiftEnabled = false;

  /// P3.3.5 — Local-serving shadow mode (parity testing path).
  /// When true (NOT this round): would run a local-serving queue in
  /// shadow alongside cloud `review_group` for parity observation. No
  /// user-facing effect, no fact/settlement change.
  static const bool isLocalServingShadowModeEnabled = false;

  /// P3.3.5 — Unified planner runtime (deferred to a later phase).
  /// When true (NOT this round): would enable unified planner runtime.
  /// This is NEVER enabled in P3.3.5 — it would require Room 1 cutover pin.
  static const bool isUnifiedPlannerRuntimeEnabled = false;

  // ==================== P3.3.6 — Shadow-Entry Prep Flags (DISABLED) ====================
  //
  // Compatibility Contract v1 + Shadow-Entry Prep flags per RF-P3.3.6-018.
  // All flags MUST remain false. Enabling any of them would require a
  // Room 1 pin AND a Phase 2 cutover decision.
  //
  // RF-P3.3.6-018: flags/seams only allowed as shadow-entry preparation,
  //                parity evidence preparation, non-runtime feature-off
  //                contracts. Default-enabled or changing current runtime
  //                truth is forbidden.

  /// P3.3.6 — Local-serving parity compare mode.
  /// When true (NOT this round): would run parity comparisons between
  /// local and cloud candidates. Evidence-only, no user-facing effect.
  static const bool isLocalServingParityCompareEnabled = false;

  /// P3.3.6 — Local-serving shadow routing.
  /// When true (NOT this round): would compute shadow routing decisions
  /// for parity comparison. Never drives actual user route;
  /// evidence-only.
  static const bool isLocalServingShadowRoutingEnabled = false;

  /// P3.3.6 — review_group compatibility mode observation flag.
  /// When true (NOT this round): would enable deeper compatibility-mode
  /// telemetry on review_group consumption. Non-runtime effect only.
  static const bool isReviewGroupCompatibilityModeEnabled = false;

  /// P3.3.6 — Local fact ingest shadow mode.
  /// When true (NOT this round): would run local-evidence → cloud-fact
  /// ingest parity comparisons. Evidence-only; final facts remain
  /// cloud-owned per RF-P3.3.6-008.
  static const bool isLocalFactIngestShadowEnabled = false;

  // ==================== P3.3.7 — Limited Execution / Shadow Mode (DISABLED) ====================
  //
  // Phase 2 Limited Execution / Shadow Mode flags.
  // All flags MUST remain false. Tests bypass these flags by calling
  // shadow classes directly. Enabling ANY of them in runtime would
  // constitute a Phase 3 cutover and requires Room 1 pin.
  //
  // RF-P3.3.7-002: shadow run enters limited execution ONLY in dev/QA/
  //                evidence layers, NEVER in user-visible runtime paths.
  // RF-P3.3.7-006: shadow results must NEVER be visible to users.

  /// P3.3.7 — Local-serving shadow run execution.
  /// When true (NOT this round): would enable shadow candidate building
  /// to run in the runtime. Stays false; shadow code reachable only by
  /// tests via `LocalServingShadowRunner.buildLocalDueQueueCandidate`.
  static const bool isLocalServingShadowRunEnabled = false;

  /// P3.3.7 — Parity check recording.
  /// When true (NOT this round): would record parity comparison results
  /// to a local evidence store. No user effect even if enabled.
  static const bool isParityCheckRecordingEnabled = false;

  /// P3.3.7 — Fact ingest shadow evaluation.
  /// When true (NOT this round): would invoke the shadow classifier
  /// alongside the real cloud submit path for parity evidence.
  /// Pure-local this round; no network calls.
  static const bool isFactIngestShadowEvaluationEnabled = false;

  /// P3.3.7 — Routing shadow computation.
  /// When true (NOT this round): would compute shadow route decisions
  /// in the home screen lifecycle. Runtime `home_word_entry = study_default`
  /// remains unchanged regardless.
  static const bool isRoutingShadowComputationEnabled = false;

  // ==================== P3.3.8 — Phase 3 Gate / Candidate Round (DISABLED) ====================
  //
  // Phase 3 gate decision + candidate migration prep flags.
  // All flags MUST remain false. These exist only so future rounds can
  // gate any evaluation wiring behind a contract pin.
  //
  // RF-P3.3.8-001: gate only judges next-layer candidate, not cutover.
  // RF-P3.3.8-008: even with prerequisites approaching, discussion only.

  /// P3.3.8 — Phase 3 gate evaluation wiring.
  /// When true (NOT this round): would enable runtime gate evaluation.
  /// Stays false; the `Phase3GateClassifier` is callable only by tests.
  static const bool isPhase3GateEvaluationEnabled = false;

  /// P3.3.8 — Limited cutover execution.
  /// When true (NOT this round): would enable execution of the minimum
  /// cutover subset. NEVER enabled in this round — any cutover requires
  /// a Room 1 formal pin first.
  static const bool isLimitedCutoverExecutionEnabled = false;

  /// P3.3.8 — DB/API candidate migration execution.
  /// When true (NOT this round): would enable seam candidate migration
  /// work. Current DB/API active baselines remain frozen at v0.2.1.
  static const bool isDbApiCandidateMigrationEnabled = false;

  // ==================== P3.3.9 — First Very Narrow Cutover (DISABLED) ====================
  //
  // First Very Narrow Cutover / ReviewPage internal serving seam flags.
  // Both flags MUST remain false. The seam in
  // `lib/core/serving/review_serving_seam.dart` is consulted by
  // `ReviewPage._loadReviewGroup()`, but with these flags OFF the seam
  // ALWAYS returns `cloudReviewGroup`. Runtime behavior is identical
  // to pre-P3.3.9 — every path still delegates to
  // `apiClient.getNextReviewGroup()`.
  //
  // RF-P3.3.9-004: only allowed runtime-truth switch candidate is
  //                ReviewPage internal serving seam very narrow subset.
  // RF-P3.3.9-005: home_word_entry, active continuation, review_group
  //                current owner, final fact/settlement MUST remain
  //                unchanged.

  /// P3.3.9 — ReviewPage non-continuation serving cutover.
  /// P3.3.16 — REAL CUTOVER: flag flipped true.
  /// S3 resolved (Option A: POST /review-attempts/local-batch).
  /// Non-continuation sessions now served from local FSRS queue.
  /// Active continuations still protected by Priority 1 (cloud retained anchor).
  static const bool isReviewPageNonContinuationCutoverEnabled = true;

  /// P3.3.9 — Stronger ingest candidate path.
  /// When true (NOT this round): would enable the stronger ingest
  /// candidate path as a formal candidate. Final fact owner stays cloud
  /// regardless — this flag does NOT authorize fact owner shift.
  /// Stays false.
  static const bool isStrongerIngestCandidatePathEnabled = false;

  // ==================== P3.3.10 — Fuller Cutover Judgment Round (DISABLED) ====================
  //
  // Fuller cutover judgment / review_group exit-gate judgment (v2) /
  // DB-API uplift judgment flags. All flags MUST remain false.
  // This round is PURE ANCHOR WORK — no runtime wiring, no runtime
  // file modifications. These flags exist only for future rounds to
  // gate judgment evaluation.
  //
  // RF-P3.3.10-003: fuller cutover judgment is NOT equivalent to
  //                 execution-ready; only grants resource qualification.
  // RF-P3.3.10-013: conclusions can only remain at judgment layer;
  //                 must not elevate to runtime truth or active baseline.

  /// P3.3.10 — Fuller cutover judgment candidate.
  /// When true (NOT this round): would enable fuller-cutover judgment
  /// evaluation. Stays false; judgment anchors are assertable from tests
  /// only.
  static const bool isFullerCutoverJudgmentCandidateEnabled = false;

  /// P3.3.10 — review_group exit-gate judgment (v2).
  /// When true (NOT this round): would enable v2 exit-gate prerequisite
  /// evaluation (adds the new `runtime` category to P3.3.8 v1's 4).
  /// Stays false; 5-category prerequisites listed only.
  static const bool isReviewGroupExitGateJudgmentV2Enabled = false;

  /// P3.3.10 — DB/API uplift judgment.
  /// When true (NOT this round): would enable uplift-judgment-ready
  /// seam family evaluation. Stays false; active DB/API baselines
  /// remain frozen at v0.2.1.
  static const bool isDbApiUpliftJudgmentEnabled = false;

  // ==================== P3.3.11 — Fuller Cutover Execution Round (DISABLED) ====================
  //
  // Fuller-cutover execution-ready / review_group exit-candidate /
  // DB-API uplift-readiness flags. All flags MUST remain false.
  // This round is PURE ANCHOR WORK — no runtime wiring.
  //
  // RF-P3.3.11-003: execution-ready ≠ production-active.
  // RF-P3.3.11-017: writeback order must be respected before any
  //                 flag can be flipped in a future round.

  /// P3.3.11 — Fuller cutover execution-ready candidate.
  /// When true (NOT this round): would enable execution-ready subset
  /// evaluation. Stays false; anchors are test-only.
  static const bool isFullerCutoverExecutionReadyEnabled = false;

  /// P3.3.11 — review_group exit-candidate.
  /// When true (NOT this round): would enable exit-candidate
  /// qualification evaluation. Stays false.
  static const bool isReviewGroupExitCandidateEnabled = false;

  /// P3.3.11 — DB/API uplift-readiness.
  /// When true (NOT this round): would enable uplift-readiness seam
  /// family evaluation. Stays false; active DB/API baselines stay at
  /// v0.2.1.
  static const bool isDbApiUpliftReadinessEnabled = false;

  // ==================== P3.3.12 — Fuller Cutover Absorb-Judgment Round (DISABLED) ====================
  //
  // Fuller-cutover absorb-candidate / true-exit-gate / DB-API
  // uplift-absorb-judgment flags. All flags MUST remain false.
  // This round is PURE ANCHOR WORK — no runtime wiring.
  //
  // RF-P3.3.12-003: absorb-candidate judgment ≠ absorbed into runtime truth.
  // RF-P3.3.12-008: true-exit-gate judgment ≠ true exit started.

  /// P3.3.12 — Fuller cutover absorb-candidate judgment.
  /// When true (NOT this round): would enable absorb-candidate judgment
  /// evaluation. Stays false; anchors are test-only.
  static const bool isFullerCutoverAbsorbCandidateJudgmentEnabled = false;

  /// P3.3.12 — review_group true-exit-gate judgment.
  /// When true (NOT this round): would enable true-exit-gate
  /// qualification judgment. Stays false.
  static const bool isReviewGroupTrueExitGateJudgmentEnabled = false;

  /// P3.3.12 — DB/API uplift-absorb judgment.
  /// When true (NOT this round): would enable uplift-absorb-judgment
  /// seam family evaluation. Stays false; active DB/API baselines stay
  /// at v0.2.1.
  static const bool isDbApiUpliftAbsorbJudgmentEnabled = false;

  // ==================== P3.3.13 — Fuller-Cutover Execution / True-Exit-Candidate / DB-API Uplift-Absorb-Readiness Round (DISABLED) ====================
  //
  // Execution-preflight layer flags. All flags MUST remain false.
  // This round is PURE ANCHOR WORK — no runtime wiring.
  //
  // RF-P3.3.13-004: execution-subset-v2 ≠ fuller cutover completed.
  // RF-P3.3.13-009: true-exit-candidate ≠ true exit started.
  // RF-P3.3.13-012: absorb-readiness ≠ active baseline uplift absorbed.

  /// P3.3.13 — Fuller cutover execution-subset-v2.
  /// When true (NOT this round): would enable widened execution-
  /// subset-v2 evaluation. Stays false; anchors are test-only.
  static const bool isFullerCutoverExecutionSubsetV2Enabled = false;

  /// P3.3.13 — review_group true-exit-candidate.
  /// When true (NOT this round): would enable true-exit-candidate
  /// evaluation. Stays false; `review_group` keeps all 4 roles.
  static const bool isReviewGroupTrueExitCandidateEnabled = false;

  /// P3.3.13 — DB/API uplift-absorb-readiness.
  /// When true (NOT this round): would enable uplift-absorb-readiness
  /// seam family evaluation. Stays false; active DB/API baselines
  /// stay at v0.2.1.
  static const bool isDbApiUpliftAbsorbReadinessEnabled = false;

  // ==================== P3.3.14 — Final Cutover Program Round (A/B/C) ====================
  //
  // Final Cutover Program Round — A-checkpoint judgment lock + B-checkpoint
  // narrow real execution + C-checkpoint absorb / cleanup gate. The 3 flags
  // below remain false because this round is ADDITIVE (new adapter family,
  // new neutral copy, new minimal binding seam) — nothing flips user-visible
  // runtime truth. Flipping any flag to true would require a separate Room 1
  // pin for either true-exit absorption, uplift absorption, or cleanup closeout.
  //
  // RF-P3.3.14-004: A checkpoint pass gate — judgment lock pinned, not
  //                 runtime truth advanced.
  // RF-P3.3.14-008: B checkpoint pass gate — real execution stays additive,
  //                 no homepage route / active continuation / final fact
  //                 owner touch.
  // RF-P3.3.14-018: C entry conditions — must hold before same-round cleanup
  //                 can be absorbed.

  /// P3.3.14 — Final cutover judgment lock enforcement.
  /// When true (NOT this round): would enable runtime enforcement of
  /// the A-checkpoint judgment lock. Stays false; the lock is pinned
  /// as an anchor contract only.
  static const bool isFinalCutoverJudgmentLockEnabled = false;

  /// P3.3.14 — Real cutover execution subset activation.
  /// When true (NOT this round): would mark the B-checkpoint real
  /// execution subset as active runtime truth. Stays false; B members
  /// are delivered additively alongside the existing runtime and do
  /// NOT replace or reroute anything.
  static const bool isRealCutoverExecutionSubsetEnabled = false;

  /// P3.3.14 — Same-round cleanup gate enabled.
  /// When true (NOT this round): would open the C-checkpoint cleanup
  /// closeout path. Stays false; the gate is pinned but NOT open.
  /// Default state this round: `notReady`.
  static const bool isSameRoundCleanupGateEnabled = false;

  // ==================== P3.3.15 — Direct Cutover Scaffolding (flag stays false) ====================
  //
  // Per R1_to_R4_P3_3_15_DirectCutover_Execution_Handoff_v0.1.md, this
  // round was handed off as a "direct cutover round" but analysis
  // revealed a hard contradiction with the out-of-scope list: a real
  // runtime source switch on ReviewPage's narrow subset cannot
  // coexist with (a) "no API core semantics rewrite" and (b) "final
  // fact / settlement owner stays at backend". A local-origin group
  // ID cannot round-trip through submitReviewAttempt, which is keyed
  // on a backend-issued group ID and returns settlement +
  // dailyGoalStatus.
  //
  // User decision this round: build the missing local-serving
  // infrastructure as real runtime code, but leave
  // `isReviewPageNonContinuationCutoverEnabled` at false. Flipping
  // the flag is parked on a future Room 1 decision about settlement
  // ownership for local-origin sessions (S3).
  //
  // S1 (LocalReviewQueueBuilder) + S2 (ReviewPage branching) +
  // S4 (RollbackHoldFallbackRuntimeWatcher) are all landed but
  // DORMANT. The existing cutover flag is NOT touched.
  //
  // The landed-marker flag below is TRUE (not a behavior gate, a
  // presence assertion) so tests can verify the scaffolding is
  // present without needing to introspect individual files.

  /// P3.3.15 — Direct-cutover scaffolding present (landed-marker, not
  /// a behavior gate). Always true once S1/S2/S4 are in the tree;
  /// flipping this to false would be a regression. Does NOT enable
  /// any user-visible behavior — that remains gated by
  /// `isReviewPageNonContinuationCutoverEnabled`, which stays false.
  static const bool isP3315DirectCutoverScaffoldingLanded = true;
}
