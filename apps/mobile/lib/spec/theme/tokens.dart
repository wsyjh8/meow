import 'package:flutter/material.dart';

/// SPEC Section 3 — Design Tokens
///
/// All values are pixel-perfect from SPEC.md.
/// Rules:
/// - Only font weights 400 and 500. NEVER 600/700.
/// - Zero shadows in entire app (except system focus rings).
/// - Zero gradients.
/// - Minimum font size 11px.

// =============================================================================
// 3.1.1 Background Colors
// =============================================================================
abstract final class SpecBg {
  /// Global background — warm beige, NOT pure white
  static const Color canvas = Color(0xFFFDFBF7);

  /// Card background (primary)
  static const Color card = Color(0xFFF5EFE6);

  /// Card background (emphasis)
  static const Color cardDeep = Color(0xFFECE0CC);

  /// Outline card background (same as canvas)
  static const Color cardOutline = Color(0xFFFDFBF7);

  /// Mochi warm card
  static const Color mochiWarm = Color(0xFFFAECE7);

  /// Purple hero
  static const Color heroPurple = Color(0xFFEEEDFE);

  /// Green highlight
  static const Color highlightGreen = Color(0xFFE1F5EE);
}

// =============================================================================
// 3.1.2 Text Colors
// =============================================================================
abstract final class SpecText {
  /// Primary text
  static const Color primary = Color(0xFF2C2C2A);

  /// Secondary text
  static const Color secondary = Color(0xFF888070);

  /// Tertiary / hint
  static const Color tertiary = Color(0xFFB4A89A);

  /// Purple (numbers, emphasis)
  static const Color purple = Color(0xFF6B4FA8);

  /// Purple deep (titles)
  static const Color purpleDeep = Color(0xFF26215C);

  /// Coral (streaks, positive highlights)
  static const Color coral = Color(0xFF993C1D);

  /// Mochi brown (Mochi card text)
  static const Color mochi = Color(0xFF4A1B0C);

  /// Green (highlight card text)
  static const Color green = Color(0xFF04342C);
}

// =============================================================================
// 3.1.3 Theme / Brand Colors
// =============================================================================
abstract final class SpecBrand {
  /// Primary CTA purple
  static const Color purple = Color(0xFF6B4FA8);

  /// Purple deep (heatmap darkest)
  static const Color purpleDeep = Color(0xFF534AB7);

  /// Mochi rose (Mochi page CTA)
  static const Color mochiRose = Color(0xFFD4537E);
}

// =============================================================================
// 3.1.4 Border Colors
// =============================================================================
abstract final class SpecBorder {
  /// Card border default — 0.5px
  static const Color defaultColor = Color(0xFFE8DFCF);

  /// List divider — 0.5px
  static const Color divider = Color(0xFFECE3D2);

  /// Icon stroke (unselected)
  static const Color icon = Color(0xFFC9B8A0);

  /// Icon stroke (selected)
  static const Color iconActive = Color(0xFFB8845C);

  /// Standard border width
  static const double width = 0.5;
}

// =============================================================================
// 3.1.5 Mochi Character Palette (DO NOT MODIFY)
// =============================================================================
abstract final class SpecMochi {
  static const Color furLight = Color(0xFFF5DEB3);
  static const Color furDark = Color(0xFFE8C99A);
  static const Color shadow = Color(0xFFE8B89C);
  static const Color innerEar = Color(0xFFF0B89C);
  static const Color blush = Color(0xB3F4C0D1); // opacity 0.7
  static const Color nose = Color(0xFFD88B7A);
  static const Color eyes = Color(0xFF3A2820);
  static const Color whiskers = Color(0xFF8A6A55);
}

// =============================================================================
// 3.2 Typography
// =============================================================================
abstract final class SpecTypo {
  /// Font family stack
  /// On Flutter, system font handles this automatically.
  /// PingFang SC on iOS, system sans-serif on Android.

  // --- Sizes ---
  /// Large numbers (stats hero) — 36-38px, w500
  static const double sizeLargeNumber = 37.0;

  /// Page title — 18px, w500
  static const double sizePageTitle = 18.0;

  /// Block large numbers — 22-24px, w500
  static const double sizeBlockNumber = 23.0;

  /// Medium numbers — 15-18px, w500
  static const double sizeMediumNumber = 16.0;

  /// Card title / body — 13-15px, w400/w500
  static const double sizeCardTitle = 15.0;
  static const double sizeCardBody = 14.0;
  static const double sizeCardSmall = 13.0;

  /// Secondary labels — 11-12px, w400
  static const double sizeLabel = 12.0;
  static const double sizeLabelSmall = 11.0;

  /// Status bar / tiny hints — 10-11px, w400
  static const double sizeTiny = 10.0;

  // --- Weights (ONLY 400 and 500, NEVER 600/700) ---
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;

  // --- Pre-built TextStyles ---
  static const TextStyle largeNumber = TextStyle(
    fontSize: sizeLargeNumber,
    fontWeight: medium,
    color: SpecText.purple,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: sizePageTitle,
    fontWeight: medium,
    color: SpecText.primary,
  );

  static const TextStyle blockNumber = TextStyle(
    fontSize: sizeBlockNumber,
    fontWeight: medium,
    color: SpecText.purple,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: sizeCardTitle,
    fontWeight: medium,
    color: SpecText.primary,
  );

  static const TextStyle cardBody = TextStyle(
    fontSize: sizeCardBody,
    fontWeight: regular,
    color: SpecText.primary,
  );

  static const TextStyle cardSmall = TextStyle(
    fontSize: sizeCardSmall,
    fontWeight: regular,
    color: SpecText.secondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: sizeLabel,
    fontWeight: regular,
    color: SpecText.secondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: sizeLabelSmall,
    fontWeight: regular,
    color: SpecText.tertiary,
  );

  static const TextStyle tiny = TextStyle(
    fontSize: sizeTiny,
    fontWeight: regular,
    color: SpecText.tertiary,
  );
}

// =============================================================================
// 3.3 Border Radius
// =============================================================================
abstract final class SpecRadius {
  /// List items, small cards
  static const double small = 16.0;

  /// Standard cards
  static const double card = 16.0;

  /// Large cards (data hero, book card)
  static const double large = 20.0;

  /// Primary CTA button
  static const double cta = 22.0;

  /// Pill (胶囊)
  static const double pill = 999.0;

  /// Heatmap cell
  static const double heatmap = 3.0;

  // --- BorderRadius helpers ---
  static final BorderRadius smallRadius = BorderRadius.circular(small);
  static final BorderRadius cardRadius = BorderRadius.circular(card);
  static final BorderRadius largeRadius = BorderRadius.circular(large);
  static final BorderRadius ctaRadius = BorderRadius.circular(cta);
  static final BorderRadius pillRadius = BorderRadius.circular(pill);
}

// =============================================================================
// 3.4 Spacing
// =============================================================================
abstract final class SpecSpacing {
  /// Page left/right margin
  static const double pageH = 22.0;

  /// Card vertical spacing
  static const double cardGap = 16.0;

  /// Card internal padding (small)
  static const double cardPadSm = 13.0;

  /// Card internal padding (large)
  static const double cardPadLg = 20.0;

  /// Element small spacing
  static const double elementGap = 10.0;

  /// Tab bar height (including safe area)
  static const double tabBarHeight = 64.0;

  /// Tab icon-label gap
  static const double tabIconLabelGap = 3.5;

  /// Min touch target
  static const double minTouch = 44.0;
}

// =============================================================================
// 3.5 Shadows — NONE except this single exception
// =============================================================================
abstract final class SpecShadow {
  /// Light floater only (e.g., "+1 new photo" pill)
  static final List<BoxShadow> floater = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  /// Default: no shadow
  static const List<BoxShadow> none = [];
}

// =============================================================================
// Tab Bar Icon Sizing
// =============================================================================
abstract final class SpecTabIcon {
  /// Normal tab icon size
  static const double size = 24.0;

  /// Mochi tab icon size (slightly larger)
  static const double mochiSize = 26.0;

  /// Tab label size
  static const double labelSize = 10.0;
}
