/// review_serving_observability_v1 (FROZEN, P3.3.9)
///
/// Observability event types + minimum floor for the first-cutover seam.
/// Observability is dev/test/QA only — NEVER user-visible.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.9-019: minimum observability includes:
///                - subset hit / miss evidence
///                - retained-anchor engaged evidence
///                - rollback engaged evidence
///                - hold engaged evidence
///                - compare mismatch bucket evidence
///                - no-final-fact-owner-switch assertion evidence
///
/// Room 5 §11: observability events must NEVER become user-visible
/// state declarations. Copy like "mode switching in progress" or
/// "已回退到旧方案" is explicitly forbidden in user UI.
library;

/// The 6 observability event kinds tracked by the first-cutover seam.
///
/// These cover the minimum floor from RF-P3.3.9-019. Additional
/// event types may be added in future rounds but none may be removed.
enum ReviewServingObservabilityEvent {
  /// 1. Seam was consulted and returned a selection.
  /// Tracks subset hit / miss evidence.
  seamHit,

  /// 2. Fallback to retained anchor was engaged.
  /// Tracks retained-anchor engagement (active continuation OR
  /// local path not wired).
  retainedAnchorEngaged,

  /// 3. Rollback was engaged (a rollback trigger fired).
  rollbackEngaged,

  /// 4. Hold was engaged (a hold trigger fired).
  holdEngaged,

  /// 5. Compare mismatch detected (e.g., during parity checks).
  /// Tracks compare mismatch bucket evidence.
  compareMismatch,

  /// 6. Assertion that final fact owner did NOT switch.
  /// Tracks no-final-fact-owner-switch assertion evidence.
  noFinalFactOwnerSwitchAssertion,
}

abstract final class ReviewServingObservabilityFloor {
  /// Canonical ordered list of the 6 minimum observability events.
  /// Tests assert this list has exactly 6 entries.
  static const List<String> kMinimumEvents = [
    'seam_hit',
    'retained_anchor_engaged',
    'rollback_engaged',
    'hold_engaged',
    'compare_mismatch',
    'no_final_fact_owner_switch_assertion',
  ];

  /// Observability canonical rule: events stay in dev/test/QA only.
  /// Tests assert this constant is referenced wherever observability
  /// events are used.
  static const String kCanonicalRule =
      'observability_events_stay_in_dev_test_qa_never_user_visible';

  /// Forbidden user-visible observability claims.
  /// Observability must NEVER surface as user-facing copy.
  /// Tests assert none of these appear in any visible UI.
  static const List<String> kForbiddenUserVisibleObservabilityClaims = [
    'mode switching in progress',
    'switched back to old plan',
    'new plan unavailable',
    '已回退到旧方案',
    '本地 serving 失败，已切回云端',
    '新规划暂不可用',
    '因 candidate mismatch 已停止切换',
  ];
}
