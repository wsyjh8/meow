/// session_entry_and_routing_compat_v1 (FROZEN, P3.3.6)
///
/// Contract anchor for future routing candidates.
/// Current runtime continues `home_word_entry = study_default`.
/// Active continuation remains high-priority but NO silent reroute.
///
/// This file is a CONTRACT ANCHOR — it exposes enums and constants that
/// EXPRESS the frozen routing decisions. It does not perform any routing
/// and is not consumed by any runtime routing path.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.6-011: current runtime continues `home_word_entry = study_default`.
///                - Home "背单词" continues as study_default (not review)
///                - active continuation remains high-priority
///                - no silent reroute (enforced since P3.3.2)
///                Forbidden:
///                  - writing current home entry as auto-routing
///                  - silently swallowing active continuation
///                  - writing future planner-aware routing as current truth
///
/// RF-P3.3.6-012: future routing compatibility only allowed as
///                shadow/candidate markers, NOT runtime.
///                Allowed: future routing possibly impacted by local-
///                serving candidate; future active continuation adoption
///                method possibly rewritten; helper/CTA/priority block
///                possibly changed with serving owner.
///                Forbidden: auto-routing runtime, mixed routing runtime,
///                silent reroute runtime.
library;

/// Routing candidate types — ALL are shadow-only markers this round.
///
/// None of these are currently consumed by runtime routing logic.
/// Every enum value corresponds to a future hypothetical that is
/// expressed here purely as a contract anchor.
enum RoutingCandidateType {
  /// What routing would be IF local-serving were active.
  /// Shadow-only — used for parity comparison, never drives user route.
  /// Current use: hidden decision evidence, test/debug.
  shadowRoutingCandidate,

  /// What home entry COULD be if planner-aware routing were enabled.
  /// Instead of hardcoded `study_default`, would be "best activity based
  /// on local plan". Candidate data only — never shown to user, never
  /// drives actual home route.
  plannerAwareEntryCandidate,

  /// What active continuation adoption WOULD look like under local-serving.
  /// Currently active continuation is independent UI block; future could
  /// be unified with local due candidate. Candidate only — never replaces
  /// current continuation UI block or judgment logic.
  continuationLocalCompatCandidate,
}

/// Contract anchor constants for session entry and routing compatibility.
abstract final class SessionEntryRoutingCompat {
  /// Current runtime home word entry — frozen as `study_default`.
  /// RF-P3.3.6-011: this MUST NOT change until Room 1 pins the cutover.
  static const String kCurrentHomeWordEntry = 'study_default';

  /// Current runtime continuation policy — high priority but independent CTA.
  /// No silent reroute (enforced since P3.3.2's session_entry_policy_v1).
  static const String kCurrentContinuationPolicy =
      'independent_cta_no_silent_reroute';

  /// Canonical list of the 3 routing candidate type names.
  /// Tests assert this list has exactly 3 entries.
  static const List<String> kAllCandidateTypeNames = [
    'shadow_routing_candidate',
    'planner_aware_entry_candidate',
    'continuation_local_compat_candidate',
  ];

  /// Forbidden auto-routing claims — must never appear in user-facing UI.
  /// Tests assert none of these appear in any visible copy.
  static const List<String> kForbiddenAutoRoutingClaims = [
    '系统已自动为你选择更优入口',
    '系统已自动判断今天先复习',
    'auto-routing 已开启',
    'mixed session 已启用',
    'planner-aware 首页已生效',
    '点击背单词按本地规划自动改路由',
    'shadow-routing 已对用户生效',
  ];
}
