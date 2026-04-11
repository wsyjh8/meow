/// deprecation_markers_and_writeback_plan_v1 (FROZEN, P3.3.6)
///
/// The four semantic layers all P3.3.6+ contract work must distinguish.
/// Downstream code, tests, write-back patches, and doc drafts MUST mark
/// which layer each element belongs to.
///
/// This file is a CONTRACT ANCHOR — it exposes the `SemanticLayer` enum
/// that serves as the single source of truth for layer classification.
/// It does not gate any runtime behavior and is not consumed by runtime
/// paths.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.6-013: four semantic layers must be explicitly marked.
///                Every patch / test / helper / code element should carry
///                at least one of these classifications.
///
/// RF-P3.3.6-014: deprecated candidate ≠ current truth AND ≠ deleted.
///                Cannot be written as "current active truth" and
///                cannot be written as "already exited / deleted /
///                migrated". Canonical phrasing: "possibly exit in
///                future" compatibility object, neither current owner
///                nor disappeared object.
library;

/// The four semantic layers for classifying any contract element.
///
/// These layers are NOT mutually exclusive — a single element can
/// legitimately occupy multiple layers. For example, cloud `review_group`
/// is simultaneously `runtimeTruth` AND `compatibilityOnly` AND
/// `deprecatedCandidate` in P3.3.6.
///
/// Cross-layer writes are always escalation triggers. For example,
/// turning a `shadowOnlyEvidence` item into `runtimeTruth` is equivalent
/// to a runtime owner shift and requires Room 1 cutover pin.
enum SemanticLayer {
  /// Layer 1: RUNTIME TRUTH
  ///
  /// Currently active in user-facing UX. Drives user decisions.
  /// Source of what users actually see and what gets recorded as fact.
  ///
  /// Criteria:
  ///   - user-observable
  ///   - production decision-making
  ///   - any change affects users immediately
  ///
  /// Examples (P3.3.6): cloud `review_group` queue, `/me/today` response,
  /// cloud settlement, cloud daily_goal, cloud streak, ReviewPage current
  /// serving chain, `home_word_entry = study_default`.
  runtimeTruth,

  /// Layer 2: COMPATIBILITY-ONLY
  ///
  /// Defined as anchor for future transition. Not currently decision-
  /// making. Can be tested, documented, code-commented. Will likely
  /// be rewritten when a cutover occurs.
  ///
  /// Criteria:
  ///   - pre-planned for future but currently passive
  ///   - provides transition anchor
  ///   - zero user-facing effect
  ///
  /// Examples (P3.3.6): `local_serving_candidate_contract_v1` anchor,
  /// `fact_settlement_ingest_contract_candidate_v1` anchor,
  /// `review_group_compatibility_posture_v1` anchor,
  /// `session_entry_and_routing_compat_v1` anchor.
  compatibilityOnly,

  /// Layer 3: DEPRECATED CANDIDATE
  ///
  /// Explicitly marked for future phase-out. Currently still functional
  /// (same behavior as runtime truth). Cannot be written as "already
  /// exited" or "already deleted". Prevents silent drift.
  ///
  /// Criteria:
  ///   - future phase-out timeline is set
  ///   - current operation unchanged
  ///   - marked in code comments / docs / tests
  ///   - NOT marked as "removed" or "retired"
  ///
  /// Examples (P3.3.6): cloud `review_group` now dual-tagged as both
  /// runtime owner AND deprecated candidate. `ApiClient.getNextReviewGroup()`
  /// and `ApiClient.submitReviewAttempt()` are marked as deprecation
  /// candidates in their doc comments since P3.3.5.
  deprecatedCandidate,

  /// Layer 4: SHADOW-ONLY EVIDENCE
  ///
  /// Running parallel to runtime (or preparing to), producing comparable
  /// evidence. Never visible to user. Zero production impact. Results
  /// never written as runtime fact.
  ///
  /// Criteria:
  ///   - hidden from user
  ///   - evidence-gathering only
  ///   - zero production impact
  ///   - results never promoted to runtime fact
  ///
  /// Examples (P3.3.6): local due queue shadow, local fact ingest shadow,
  /// shadow routing candidate, parity check results. All gated behind
  /// disabled feature flags this round.
  shadowOnlyEvidence,
}

/// Contract anchor constants for the four-layer semantic classification.
abstract final class SemanticLayerContract {
  /// Canonical ordered list of the 4 semantic layer names.
  /// Tests assert this list has exactly 4 entries in this exact order.
  static const List<String> kAllLayerNames = [
    'runtime_truth',
    'compatibility_only',
    'deprecated_candidate',
    'shadow_only_evidence',
  ];

  /// Forbidden deprecation claims — deprecated candidate must never be
  /// written as already exited/deleted/switched away.
  /// RF-P3.3.6-014: deprecated candidate ≠ current truth AND ≠ deleted.
  static const List<String> kForbiddenDeprecationClaims = [
    '已废弃',
    '已退场',
    '即将不可用',
    '已切换新方案',
    '已删除旧逻辑',
    '已被 local 接管',
  ];
}
