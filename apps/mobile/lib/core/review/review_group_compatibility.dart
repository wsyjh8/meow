/// review_group_compatibility_contract_v1 (FROZEN, P3.3.5)
/// review_group_compatibility_posture_v1 (FROZEN, P3.3.6) — 3-layer posture
///
/// This file is a CONTRACT ANCHOR — it captures Room 1's P3.3.5 and
/// P3.3.6 pinned decisions for the future migration of the planner
/// owner. It does not run code; it only exposes constants for tests
/// and for other files to reference as the single source of truth.
///
/// ============================================================================
/// P3.3.6 extension: explicit 3-layer posture
/// ============================================================================
///
/// RF-P3.3.6-005: `review_group` is still runtime serving owner.
/// RF-P3.3.6-006: simultaneously compatibility anchor + deprecated candidate.
/// RF-P3.3.6-007: deprecated candidate ≠ already retired.
///
/// The three layers are NOT mutually exclusive. `review_group` now
/// simultaneously occupies all three this round. See constants at the
/// bottom of `ReviewGroupCompatibility` for the posture flags.
///
/// ============================================================================
/// RF-P3.3.5-006: `review_group` enters compatibility / deprecation path
/// ============================================================================
///
/// - Current runtime: `review_group` IS the current ReviewPage serving
///   truth owner. Runtime consumers MUST continue to call the cloud
///   `review_group` API paths.
/// - Future target-state candidate: local planner owner shift.
/// - This round: mark deprecation CANDIDACY in comments; DO NOT delete,
///   bypass, or silently rewrite runtime behavior.
///
/// RF-P3.3.5-015: `review_group` / cloud readiness enters staged
/// deprecation — NOT "disappeared". Runtime must continue to consume it.
///
/// RF-P3.3.5-016: deprecated MUST NOT be written as active truth, and
/// MUST NOT be pretended to be fully migrated.
///
/// ============================================================================
/// Three-layer owner split (RF-P3.3.5-002, RF-P3.3.5-003)
/// ============================================================================
///
///   A. PLANNING OWNER
///      - Future direction: local FSRS scheduler
///      - Current runtime: N/A (no committed planner owner)
///      - Responsible for: due / overdue / interval / stability /
///                         difficulty / local review session candidate
///
///   B. SERVING OWNER
///      - Current runtime: cloud `review_group`
///      - Future target-state candidate: local-serving contract
///      - Responsible for: ReviewPage queue / continuation /
///                         completion / group lifecycle
///
///   C. FACT / SETTLEMENT OWNER
///      - Current runtime: cloud / backend fact layer
///      - This round: NOT a cut candidate
///      - Responsible for: valid review fact, today's goal completion,
///                         reward settlement, streak, daily_goal
///
/// RF-P3.3.5-003: local owner shift does not automatically bring
/// fact owner shift. Each layer must be evaluated independently.
///
/// ============================================================================
/// Deprecation markers list (code-side only; for future reference)
/// ============================================================================
///
///   - `ApiClient.getNextReviewGroup()` — current runtime path
///   - `ApiClient.submitReviewAttempt()` — current runtime path
///   - `ReviewPage._loadReviewGroup()` — current runtime consumer
///   - `ReviewPage._onRate()` — current runtime consumer (cloud-first)
///   - `ReviewGroup` / `ReviewGroupItem` DTO shapes — current runtime types
///
/// ============================================================================
/// Forbidden claims (must never appear in UI or runtime behavior)
/// ============================================================================
///
///   - 本地 planner 已接管复习主链路
///   - ReviewPage 已由本地 planner 驱动
///   - 当前复习主真相源已切换到本地
///   - `review_group` 已退出运行态
///   - 云端不再参与复习主链路
///   - unified planner 已成立
///   - auto-routing 已开启
///   - 已切换到最佳复习模式
///   - 本地计划已接管
library;

/// Three-layer planner owner split.
///
/// This enum EXPRESSES the split — it does not EXECUTE it.
/// Current runtime has NOT shifted; only the serving layer has a future
/// target-state candidate (local-serving). Planning and fact/settlement
/// layers are not cut candidates in this round.
enum PlannerOwnerLayer {
  /// Planning owner: future direction = local FSRS.
  /// Current runtime: no committed planning owner.
  /// Responsible for: scheduling candidate signals only.
  planning,

  /// Serving owner: current runtime = cloud `review_group`.
  /// Future target-state candidate: local-serving contract.
  /// Responsible for: ReviewPage queue / continuation / completion.
  serving,

  /// Fact / settlement owner: current runtime = cloud backend.
  /// NOT a cut candidate this round.
  /// Responsible for: reward, streak, daily_goal, review fact.
  factSettlement,
}

/// Contract anchor constants for `review_group` compatibility / deprecation.
///
/// These constants lock in Room 1's P3.3.5 decisions so tests can assert
/// the current runtime truth has not silently drifted.
abstract final class ReviewGroupCompatibility {
  /// Current runtime serving truth owner — frozen as cloud this round.
  /// Even when future local-serving candidate is added, this MUST NOT
  /// change until Room 1 pins the cutover.
  static const String kCurrentServingOwner = 'cloud_review_group';

  /// Current runtime fact/settlement owner — NOT a cut candidate.
  /// RF-P3.3.5-003: local owner shift does not automatically bring
  /// fact owner shift.
  static const String kCurrentFactOwner = 'cloud_backend';

  /// `review_group` runtime status this round.
  ///
  /// Canonical value: 'runtime_active_deprecation_candidate'
  ///   - runtime_active: still consumed by the runtime (ReviewPage)
  ///   - deprecation_candidate: annotated as a future deprecation target
  ///
  /// This is NOT the same as "deprecated" or "removed" — the runtime
  /// still owns it as current truth.
  static const String kReviewGroupStatus =
      'runtime_active_deprecation_candidate';

  /// Canonical phrase anchors for test assertions.
  static const String kRuntimeActiveTag = 'runtime_active';
  static const String kDeprecationCandidateTag = 'deprecation_candidate';

  /// Forbidden owner-shift claim phrases.
  /// Tests assert none of these appear in any visible UI copy.
  static const List<String> kForbiddenOwnerShiftClaims = [
    '本地 planner 已接管复习主链路',
    '本地planner已接管复习主链路',
    'ReviewPage 已由本地 planner 驱动',
    '当前复习主真相源已切换到本地',
    'review_group 已退出运行态',
    '云端不再参与复习主链路',
    'unified planner 已成立',
    'auto-routing 已开启',
    '已切换到最佳复习模式',
    '本地计划已接管',
  ];

  // ==================== P3.3.6 — Three-Layer Posture ====================
  //
  // review_group_compatibility_posture_v1 (FROZEN, P3.3.6):
  //   `review_group` simultaneously occupies THREE layers this round:
  //     1. runtime serving owner (RF-P3.3.6-005)
  //     2. compatibility anchor (RF-P3.3.6-006)
  //     3. deprecated candidate (RF-P3.3.6-006, NOT retired per RF-P3.3.6-007)
  //
  // These are not mutually exclusive. The posture prevents different
  // downstream documents from each writing a different version of
  // "what review_group is right now".

  /// Layer 1: runtime serving owner — cloud review_group IS currently
  /// the ReviewPage queue source and serving main chain (RF-P3.3.6-005).
  static const bool kPostureRuntimeOwner = true;

  /// Layer 2: compatibility anchor — review_group provides reference
  /// truth for future shadow/parity comparison (RF-P3.3.6-006).
  static const bool kPostureCompatibilityAnchor = true;

  /// Layer 3: deprecated candidate — review_group is marked as a
  /// future deprecation target, but NOT retired this round
  /// (RF-P3.3.6-006 + RF-P3.3.6-007).
  static const bool kPostureDeprecatedCandidate = true;

  /// Canonical 3-layer posture status string.
  /// Tests assert this contains all three layer tags.
  static const String kThreeLayerPostureStatus =
      'runtime_owner_plus_compatibility_anchor_plus_deprecated_candidate';
}
