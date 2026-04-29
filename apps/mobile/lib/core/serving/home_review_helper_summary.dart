/// home_review_helper_summary (FROZEN, P3.3.14 — B checkpoint additive)
///
/// Member 3 of `real_cutover_execution_subset_v1`. Retained-anchor-
/// aware review helper / summary / no-review-state layer for the home
/// page. Provides a small widget + caption constants that the home
/// page can render ADDITIVELY, alongside the existing quick-review
/// CTA.
///
/// **This does NOT change the home page primary route.** `home_word_entry`
/// remains `study_default`. The helper summary is a supplementary
/// caption that makes the retained-anchor posture visible to QA /
/// observability; it does NOT claim planner-aware routing, auto-routing,
/// or any review-source switch.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.14-005: B checkpoint allowed execution direction — Member 3.
/// RF-P3.3.14-006: B checkpoint forbidden layer — home default route
///                 switch, active continuation source switch,
///                 planner-aware route.
/// RF-P3.3.14-017: fact-owner overclaim prohibitions.
library;

import 'package:flutter/material.dart';

/// The 4 visible states of the home review helper summary. All 4 are
/// retained-anchor-aware — none of them claim any source switch.
enum HomeReviewHelperSummaryState {
  /// Review is available now via cloud review_group.
  reviewAvailable,

  /// No review is pending in the retained anchor right now.
  noReviewPending,

  /// Review state is temporarily unservable (network / server).
  temporarilyUnservable,

  /// Review state is still loading.
  loading,
}

abstract final class HomeReviewHelperSummary {
  /// Retained-anchor-aware neutral caption for "review available".
  /// Tests assert exact string equality.
  static const String kCaptionReviewAvailable = '复习就绪，可随时开始';

  /// Retained-anchor-aware neutral caption for "no review pending".
  /// Must NOT say "today done", "no quota", "local queue empty".
  static const String kCaptionNoReviewPending = '暂无待复习，先去背单词吧';

  /// Retained-anchor-aware neutral caption for "temporarily unservable".
  /// Must NOT say "new plan unavailable" or "rollback to old plan".
  static const String kCaptionTemporarilyUnservable = '复习稍后再试';

  /// Retained-anchor-aware neutral caption for "loading".
  static const String kCaptionLoading = '加载中';

  /// Mapping from state to canonical caption.
  /// Tests assert length == 4 and exact string equality per state.
  static const Map<HomeReviewHelperSummaryState, String> kCaptionByState = {
    HomeReviewHelperSummaryState.reviewAvailable: kCaptionReviewAvailable,
    HomeReviewHelperSummaryState.noReviewPending: kCaptionNoReviewPending,
    HomeReviewHelperSummaryState.temporarilyUnservable:
        kCaptionTemporarilyUnservable,
    HomeReviewHelperSummaryState.loading: kCaptionLoading,
  };

  /// All captions for test enumeration. Tests iterate and assert no
  /// forbidden substring appears.
  static const List<String> kAllCaptions = [
    kCaptionReviewAvailable,
    kCaptionNoReviewPending,
    kCaptionTemporarilyUnservable,
    kCaptionLoading,
  ];

  /// Canonical rule for this layer.
  /// Tests assert this contains 'home_word_entry_remains_study_default'.
  static const String kCanonicalRule =
      'home_review_helper_summary_is_retained_anchor_aware_additive_caption_'
      'home_word_entry_remains_study_default_and_does_not_reroute_primary_route';

  /// Semantic boundary. Tests assert this contains 'additive_caption'.
  static const String kSemanticBoundary =
      'additive_caption_does_not_equal_primary_route_change_and_does_not_equal_'
      'planner_aware_routing';
}

/// A small additive retained-anchor-aware caption widget for the home
/// page. Takes a state and renders the canonical caption in a small
/// tertiary text style. Adds no interactivity, no side effects.
///
/// The parent widget is responsible for placing this where it fits
/// the existing layout — the widget itself does not position or
/// decorate itself.
class HomeReviewHelperSummaryCaption extends StatelessWidget {
  final HomeReviewHelperSummaryState state;

  const HomeReviewHelperSummaryCaption({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final caption = HomeReviewHelperSummary.kCaptionByState[state]!;
    return Text(
      caption,
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey[500],
        fontWeight: FontWeight.normal,
      ),
    );
  }
}
