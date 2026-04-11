/// review_readiness_policy_v1 (FROZEN, P3.3.3)
///
/// 4 minimum readiness semantics for the review path.
///
/// **Truth source rule (RF-P3.3.3-001 through RF-P3.3.3-004):**
/// Page-level readiness truth MUST come from the cloud review-serving layer
/// (i.e., the response from `getNextReviewGroup()` and related cloud signals).
/// Local FSRS is scheduling candidate input ONLY — it is NOT the readiness
/// truth source and MUST NOT be used to derive page-level readiness facts.
///
/// **Owner:** cloud `review_group` serving layer
/// **NOT owner:** local FSRS due-card count / local card state
enum ReviewReadinessState {
  /// RF-P3.3.3-001 — `ready_now`
  ///
  /// The review-serving layer can immediately serve review work.
  /// Canonical expression: active `review_group` exists and is in progress.
  ///
  /// UI implication: show review content / continue reviewing.
  /// MUST NOT imply local FSRS drove this readiness determination.
  readyNow,

  /// RF-P3.3.3-002 — `not_ready_now`
  ///
  /// The review-serving layer currently has no immediately servable review work.
  /// (e.g., HTTP 404 from `/me/review-groups/next` — no active or eligible group)
  ///
  /// UI implication: neutral "no review content right now" message.
  /// MUST NOT imply "no review ever", "no review quota today", or
  /// "system judged you don't need to review".
  notReadyNow,

  /// RF-P3.3.3-003 — `next_group_eligible`
  ///
  /// No active group; minimum preconditions for next-group entry are met.
  /// This is an *eligibility* state, NOT a *generation-complete* state.
  ///
  /// CRITICAL: `next_group_eligible` ≠ `next_group_generated`
  /// (RF-P3.3.3-011 from review_group_generation_policy_v1)
  ///
  /// UI implication: show eligibility-only copy, e.g., "下一组是否可用，以后端判断为准".
  /// MUST NOT say "next group already generated / downloaded / ready".
  nextGroupEligible,

  /// RF-P3.3.3-004 — `temporarily_unservable`
  ///
  /// The review-serving layer is transiently unable to provide a stable result.
  /// (e.g., network error, server error, unexpected API failure)
  ///
  /// UI implication: show neutral retry state.
  /// MUST NOT be displayed as "no review quota" or permanent denial.
  /// This is a transient state — "temporarily" is load-bearing.
  temporarilyUnservable,
}
