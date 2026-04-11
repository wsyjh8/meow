/// local_serving_candidate_contract_v1 (FROZEN, P3.3.6)
///
/// Contract anchor for future local-serving candidate concepts.
/// Room 3 ONLY freezes field group SEMANTICS this round — NOT DTO shapes,
/// field names, indexes, migrations, or API examples (RF-P3.3.6-003).
/// The 8 field semantic names below are CONCEPT anchors, not schema.
///
/// This file is a CONTRACT ANCHOR — it exposes enums and constants that
/// EXPRESS the P3.3.6 pinned decisions. It does not run code, does not
/// produce candidates, and is not consumed by any runtime path.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.6-001: `local_due_queue_candidate` is a future candidate only,
///                NOT current ReviewPage runtime truth.
///                Allowed layers: shadow candidate / compatibility contract /
///                parity comparison input.
///                Forbidden: current ReviewPage serving truth, direct
///                replacement of `review_group`, current completion/
///                settlement trigger.
///
/// RF-P3.3.6-002: `local_generated_review_session_candidate` is a future
///                candidate only, NOT current runtime main queue.
///                Allowed layers: candidate data model / adapter seam /
///                future feature-flag mount point.
///                Forbidden: current runtime user-visible route, current
///                ReviewPage main queue, direct replacement of
///                `next review group`.
///
/// RF-P3.3.6-003: Future queue source freezes ONLY field group semantics
///                this round — NOT complete DTO/schema/API. The 8 field
///                group names below are concept anchors, not a schema.
///
/// RF-P3.3.6-004: compatibility vs shadow-only boundary must be explicit.
library;

/// Source types for future serving candidates.
///
/// `cloudGroup` is the CURRENT runtime source; the two local* variants
/// are future shadow-only candidates, NOT current runtime paths.
enum LocalServingSourceType {
  /// Current runtime serving source — cloud `review_group`.
  /// This is the only source currently consumed by ReviewPage.
  cloudGroup,

  /// Future candidate — local due queue from FSRS scheduler.
  /// Currently: shadow-only, never consumed by ReviewPage.
  /// RF-P3.3.6-001: local_due_queue_candidate
  localDueShadow,

  /// Future candidate — locally generated session-level packaging.
  /// Currently: shadow-only, never consumed by ReviewPage.
  /// RF-P3.3.6-002: local_generated_review_session_candidate
  localGeneratedShadow,
}

/// Serving eligibility state for candidates.
///
/// Only `runtimeActive` means the candidate is actually consumed by
/// runtime — which applies ONLY to the cloud review_group this round.
/// All other states are gates, shadow-only, or compatibility pending.
enum ServingEligibilityState {
  /// Candidate is currently consumed by runtime.
  /// This round: applies ONLY to cloud review_group.
  runtimeActive,

  /// Candidate is eligible to serve but currently gated behind shadow.
  eligible,

  /// Candidate pending compatibility boundary check.
  pendingBoundaryCheck,

  /// Candidate is shadow-only — never consumed in runtime.
  /// This round: applies to all local* candidates.
  shadowOnly,

  /// Candidate fails current compatibility rules.
  incompatible,

  /// Candidate is waiting for parity verification result.
  parityPending,
}

/// Reason a candidate was generated / considered.
///
/// This classifies WHY a candidate exists, not WHETHER it is allowed
/// to serve runtime (which is governed by `ServingEligibilityState`).
enum CandidateReason {
  /// Produced by FSRS local scheduler computation (due / overdue / interval).
  fsrsComputed,

  /// Produced by local generation logic (session packaging).
  localGenerated,

  /// Cloud review_group — the current runtime baseline.
  cloudGroupCurrent,

  /// Produced specifically as a parity baseline for shadow comparison.
  parityBaseline,
}

/// Field group semantic names (RF-P3.3.6-003).
///
/// These are semantic CONCEPT anchors — NOT a DTO schema.
/// Future rounds may name fields differently; what matters is that
/// every future serving candidate expresses these 8 concepts.
///
/// Tests assert this list has exactly 8 entries and all canonical names.
abstract final class LocalServingCandidateFieldSemantics {
  /// Field 1: source_type — identifies origin system.
  /// Value domain: see `LocalServingSourceType`.
  static const String kFieldSourceType = 'source_type';

  /// Field 2: source_id — unique ID within origin system.
  /// E.g., review_group_id for cloud, local queue id for local.
  static const String kFieldSourceId = 'source_id';

  /// Field 3: owner_layer — planning / serving / fact_settlement.
  /// Value domain: see `PlannerOwnerLayer` in review_group_compatibility.dart.
  static const String kFieldOwnerLayer = 'owner_layer';

  /// Field 4: shadow_only — boolean boundary marker.
  /// true → candidate exists only in shadow/parity layer;
  /// false → candidate is compatibility-contract level (may be observed/
  /// tested but not user-facing).
  static const String kFieldShadowOnly = 'shadow_only';

  /// Field 5: candidate_reason — why this candidate exists.
  /// Value domain: see `CandidateReason`.
  static const String kFieldCandidateReason = 'candidate_reason';

  /// Field 6: generated_at — timestamp of candidate assembly (ISO 8601).
  static const String kFieldGeneratedAt = 'generated_at';

  /// Field 7: item_count — number of items in the candidate queue/session.
  static const String kFieldItemCount = 'item_count';

  /// Field 8: serving_eligibility_state — current serving gate state.
  /// Value domain: see `ServingEligibilityState`.
  static const String kFieldServingEligibilityState =
      'serving_eligibility_state';

  /// Canonical ordered list of all 8 field semantic names.
  /// Tests assert this list has exactly 8 entries.
  static const List<String> kAllFieldSemanticNames = [
    kFieldSourceType,
    kFieldSourceId,
    kFieldOwnerLayer,
    kFieldShadowOnly,
    kFieldCandidateReason,
    kFieldGeneratedAt,
    kFieldItemCount,
    kFieldServingEligibilityState,
  ];

  /// Forbidden claims — must never appear in user-facing UI.
  /// Tests assert none of these appear in any visible copy.
  static const List<String> kForbiddenLocalServingClaims = [
    '本地 serving 已启用',
    'ReviewPage 已切到本地队列',
    '当前复习队列来自本地 due',
    '当前 serving truth 已切换',
    'owner shift 已完成',
    '影子模式已正式生效',
    'parity 已通过，现已切换新模式',
    '当前已升级到新 serving 方案',
  ];
}
