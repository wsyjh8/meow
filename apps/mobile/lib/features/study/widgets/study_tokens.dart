import 'package:flutter/material.dart';

/// Visual tokens for the study card — "Cream Café" palette (Memo1 design
/// handoff, May 2026). Names are kept stable across the cool-grey → warm-
/// cream re-skin so call sites in `widgets/*` don't need rename churn.
///
/// Colour roles map to the design's CSS vars:
///   bg          → --bg          (page background, cream yellow)
///   cardBg      → --card        (per-section card)
///   cream       → --cream       (cream pill / icon circle bg)
///   textDark    → --ink         (primary cocoa text)
///   textMedium  → --ink-soft    (secondary text)
///   textGray    → --ink-soft    (kept as alias for old call sites)
///   purple      → --main        (caramel — "main" brand colour)
///   borderColor → --line        (hairline divider / card border)
///
/// Rating buttons use the cream-café 4-color pastel set (again-pink /
/// hard-cream / good-mint / easy-lavender) — see `RatingPalette` below.
class StudyTokens {
  StudyTokens._();

  // ── Surface ──────────────────────────────────────────────────────────────
  static const Color bg = Color(0xFFFFF6EA);          // page background
  static const Color cardBg = Color(0xFFFFFDF8);      // per-section card
  static const Color cream = Color(0xFFFFEFD9);       // cream pill / icon circle
  static const Color line = Color(0xFFF0E4D0);        // hairline border
  static const Color borderColor = line;              // alias

  // ── Ink (text) ───────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF3B2A23);         // primary cocoa
  static const Color inkSoft = Color(0xFF8A6F5E);     // secondary cocoa
  // Aliases kept for unchanged call sites in widgets/*.
  static const Color textDark = ink;
  static const Color textMedium = inkSoft;
  static const Color textGray = inkSoft;

  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color main = Color(0xFFD8A876);        // caramel brown
  static const Color mainDeep = Color(0xFFA87C4F);    // dark caramel (cat stripes)
  static const Color accent = Color(0xFFFF8A7A);      // peach (star, antonym)
  static const Color success = Color(0xFF8ABF9C);     // mint (synonym)

  // Aliases — old names map to closest cream-café equivalent.
  static const Color purple = main;                   // (was cool purple → caramel)
  static const Color softPurpleBg = cream;            // (was soft purple bg → cream)
  static const Color purpleBorder = main;             // (only used for buttons)
  static const Color orangeBg = Color(0xFFFFE4DD);    // again pill bg
  static const Color orangeBorder = Color(0xFFF4D4CA);
  static const Color orangeText = Color(0xFFC45F50);  // again pill fg
  static const Color neutralBg = cream;
  static const Color neutralBorder = line;
  static const Color neutralText = inkSoft;
  static const Color progressBg = cream;
  static const Color barBg = inkSoft;
  static const Color greenBg = Color(0xFFE5F2EB);     // syn / good
  static const Color greenText = Color(0xFF5B8870);

  // ── Rating button palette (Memo1 spec) ───────────────────────────────────
  static const RatingPalette ratingAgain =
      RatingPalette(bg: Color(0xFFFFE4DD), fg: Color(0xFFC45F50)); // 不认识
  static const RatingPalette ratingHard =
      RatingPalette(bg: Color(0xFFFFEFD9), fg: Color(0xFFB6864A)); // 模糊
  static const RatingPalette ratingGood =
      RatingPalette(bg: Color(0xFFE5F2EB), fg: Color(0xFF5B8870)); // 认识
  static const RatingPalette ratingEasy =
      RatingPalette(bg: Color(0xFFEEE5F2), fg: Color(0xFF7B6296)); // 熟悉

  // ── Radius ───────────────────────────────────────────────────────────────
  static const double radiusTag = 8;
  static const double radiusPill = 12;
  static const double radiusCard = 22;
  static const double radiusHero = 24;
  static const double radiusButton = 14;

  // ── Shadow ───────────────────────────────────────────────────────────────
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x0A3B2A23), // rgba(59,42,35,0.04)
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  // ── Typography helpers (bundled variable fonts) ──────────────────────────
  // Three families per the Memo1 spec, each shipped as a `wght`-axis
  // variable font under assets/fonts/ and registered in pubspec.yaml.
  // Flutter interpolates to the requested FontWeight automatically.
  //   serif → Fraunces   (English titles / examples / phrases)
  //   mono  → JetBrainsMono (labels / IPA / numerics / pos pills)
  //   round → Nunito     (UI copy, fish counter, section labels)
  // Chinese falls through to PingFang on iOS and the system default
  // (思源 / Roboto fallback) on other platforms — handled by Flutter.
  static const String _serifFamily = 'Fraunces';
  static const String _monoFamily = 'JetBrainsMono';
  static const String _roundFamily = 'Nunito';

  static TextStyle serif({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) =>
      TextStyle(
        fontFamily: _serifFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  static TextStyle mono({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: _monoFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle round({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: _roundFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}

class RatingPalette {
  final Color bg;
  final Color fg;
  const RatingPalette({required this.bg, required this.fg});
}
