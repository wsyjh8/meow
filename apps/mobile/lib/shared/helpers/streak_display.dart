/// P3 Phase 4 — Shared streak display helper.
///
/// This is a DISPLAY helper only, NOT business logic.
/// It centralizes streak label formatting to prevent drift across pages.
///
/// Current truth: streak is based on check_in.
/// This helper does NOT determine whether streak extends — that's backend truth.
abstract final class StreakDisplay {
  /// Current basis label — centralized so all pages stay consistent.
  /// Only change this when Room 1 pins a new streak basis.
  static const String basisLabel = '\u57fa\u4e8e\u7b7e\u5230'; // 基于签到

  /// Parenthesized basis for inline use: "(基于签到)"
  static const String basisLabelParens = '(\u57fa\u4e8e\u7b7e\u5230)'; // (基于签到)

  /// Short basis for chip suffix: "(签到)"
  static const String basisLabelShort = '(\u7b7e\u5230)'; // (签到)

  /// Format streak count: "连续 N 天"
  static String streakText(int count) => '\u8fde\u7eed $count \u5929'; // 连续 N 天

  /// Format streak count with basis: "连续 N 天 (基于签到)"
  static String streakWithBasis(int count) => '${streakText(count)} $basisLabelParens';

  /// Format streak chip label: "🔥 连续N天(签到)"
  static String streakChipLabel(int count) => '\u{1f525} \u8fde\u7eed${count}\u5929$basisLabelShort'; // 🔥 连续N天(签到)

  /// Format streak chip label for MeowHome: "🔥 N天连续(签到)"
  static String streakChipLabelAlt(int count) => '\u{1f525} ${count}\u5929\u8fde\u7eed$basisLabelShort'; // 🔥 N天连续(签到)
}
