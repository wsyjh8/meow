/// review_priority_policy_v1 (FROZEN, P3.3.3)
///
/// Priority hierarchy for review-related CTA承接 and page state selection.
///
/// **What is frozen:** the ORDER (hierarchy) only.
/// **What is NOT frozen:** complete scoring algorithm, due/high-priority weights,
/// local overdue bucket ordering, CTA winner full state-driven contract.
///
/// **Rules:**
/// - RF-P3.3.3-005: `continuation` is highest priority — but NOT silent reroute.
///   "背单词" default entry is NOT consumed by continuation priority.
/// - RF-P3.3.3-006: `dueReview` and `highPriorityReview` ONLY enter the priority
///   hierarchy when cloud-confirmed (serving-confirmed). Local FSRS overdue
///   MUST NOT be treated as a priority winner.
/// - RF-P3.3.3-007: `newWords` is the stable fallback / `study_default`.
///   When no continuation, no cloud-confirmed due/high-priority review exists,
///   the homepage continues to show "背单词" as the primary CTA.
/// - RF-P3.3.3-008: `session` continues at low priority; NOT auto-promoted
///   to highest. Current project has not entered full CTA winner / session
///   deeper policy round.
///
/// **Pending (NOT frozen this round):**
/// - Complete priority scoring
/// - due vs high-priority review weights
/// - local overdue bucket participation in ordering
/// - CTA winner full state-driven algorithm
enum ReviewPriorityLevel {
  /// Active `review_group` continuation — highest priority.
  /// Expressed via independent CTA / helper / priority block, NOT silent reroute.
  continuation,

  /// Cloud-confirmed due review.
  /// MUST have serving-layer confirmation — local FSRS due count alone is insufficient.
  dueReview,

  /// Cloud-confirmed high-priority review.
  /// MUST have serving-layer confirmation — local signals alone are insufficient.
  highPriorityReview,

  /// New words / study_default — stable fallback.
  /// This is the default when no higher priority item is cloud-confirmed.
  newWords,

  /// Session — currently lowest priority in this hierarchy.
  /// Not auto-promoted. Future deeper policy round required to change this.
  session,
}

/// Frozen priority order — highest to lowest.
///
/// Usage: index 0 = highest, last index = lowest.
/// When no cloud-confirmed signal exists for a level, skip to the next.
///
/// MUST NOT: use local FSRS due count as a signal for [dueReview] or
/// [highPriorityReview] priority winner determination.
const List<ReviewPriorityLevel> kReviewPriorityOrder = [
  ReviewPriorityLevel.continuation,
  ReviewPriorityLevel.dueReview,
  ReviewPriorityLevel.highPriorityReview,
  ReviewPriorityLevel.newWords,
  ReviewPriorityLevel.session,
];
