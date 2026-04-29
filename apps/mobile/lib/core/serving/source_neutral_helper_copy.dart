/// source_neutral_helper_copy (FROZEN, P3.3.14 — B checkpoint additive)
///
/// Member 2 of `real_cutover_execution_subset_v1`. Provides source-
/// neutral wording constants used by ReviewPage's empty-state and
/// completion-state pre-explanation layer. Wording is intentionally
/// neutral — it does NOT claim any serving-truth switch, it does NOT
/// claim any fact-owner shift, and it does NOT distinguish cloud from
/// local because this round's serving source is still exclusively
/// cloud `review_group`.
///
/// All copy here is ADDITIVE. It is displayed alongside existing
/// ReviewPage copy; it does not replace any existing text.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.14-003: 32 user-visible forbidden claims must NOT appear.
/// RF-P3.3.14-005: B checkpoint allowed execution direction — Member 2.
/// RF-P3.3.14-017: fact-owner overclaim prohibitions.
library;

abstract final class SourceNeutralHelperCopy {
  // ==================== Empty-state pre-explanation ====================

  /// Empty-state caption shown under the existing "当前暂无待复习内容"
  /// text. Source-neutral: does not say "no review quota", "today done",
  /// "local queue empty", or similar.
  /// Tests assert this string contains no forbidden-claim substrings.
  static const String kEmptyStateNeutralCaption = '来得早不如来得巧，稍后再试';

  /// Empty-state secondary caption, source-neutral hint.
  static const String kEmptyStateSecondaryCaption = '你的复习会按计划逐步出现';

  // ==================== Completion pre-explanation ====================

  /// Completion pre-explanation caption shown under "本组已完成" text
  /// to clarify the group-vs-daily boundary without claiming any
  /// truth-source switch.
  static const String kCompletionNeutralCaption = '本组进度已结算，完整结果以后端为准';

  /// Completion secondary caption — neutral phrasing about next group
  /// eligibility that does not claim auto-routing or planner-aware runtime.
  static const String kCompletionNextGroupCaption = '下一组是否可用，以后端判断为准';

  // ==================== Summary pre-explanation ====================

  /// Summary caption used when introducing the review progress row.
  /// Neutral phrasing — does not imply any local queue source.
  static const String kSummaryNeutralCaption = '本组进度（以后端复习事实为准）';

  // ==================== Forbidden claim guard ====================

  /// The 32 forbidden user-visible claim phrases. Tests assert that
  /// none of the captions above contain any of these substrings, as a
  /// runtime-adjacent overclaim guardrail.
  /// Tests assert length == 32.
  static const List<String> kForbiddenClaimSubstrings = [
    // fuller cutover / local-serving
    '本地 serving 已启用',
    'ReviewPage 已切到本地队列',
    '当前复习队列来自本地 due',
    'owner shift 已完成',
    '当前 serving truth 已切换',
    '已升级到新 serving 方案',
    // review_group true-exit / cleanup
    'review_group 已退场',
    '旧方案即将不可用',
    '当前已不再使用 review_group',
    'retained anchor 已不再需要',
    '已完成旧方案迁移',
    'old path 已清理完成',
    // uplift
    'active DB / API baseline 已升级',
    '新基线已吸收进运行态',
    '现在已按新契约运行',
    'uplift 已完成',
    // routing / planner
    '系统已自动为你选择更优入口',
    'auto-routing 已开启',
    'mixed session 已启用',
    'planner-aware 首页已生效',
    // fact / settlement
    '本地已直接记为有效复习',
    '今日进度已因本地方案更新',
    '奖励已因新主链路到账',
    'streak 已因 final cutover 续上',
    '学习事实已正式更新',
    '现在你刚刚的结果已写入最终事实',
    // migration / absorb / cleanup
    '已回退到旧方案',
    '新方案暂不可用',
    '已完成兼容切换',
    '现在你正在使用新的复习规划',
    'cutover 已完成',
    'cleanup 已完成',
  ];

  /// All caption strings for test enumeration. Tests iterate this list
  /// and assert that no caption contains any forbidden substring.
  static const List<String> kAllCaptions = [
    kEmptyStateNeutralCaption,
    kEmptyStateSecondaryCaption,
    kCompletionNeutralCaption,
    kCompletionNextGroupCaption,
    kSummaryNeutralCaption,
  ];

  /// Semantic boundary marker. Tests assert this contains 'source_neutral'.
  static const String kSemanticBoundary =
      'source_neutral_additive_copy_does_not_claim_serving_truth_switch_or_'
      'final_fact_owner_shift';
}
