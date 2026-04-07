import 'package:flutter/material.dart';

/// Meow App Design Tokens (Option B Phase 1).
///
/// "稍微偏萌" — warm, soft, slightly cute but not childish.
/// Learning pages stay clean; companion pages can be warmer.

// ========== Colors ==========

class MeowColors {
  MeowColors._();

  // Primary
  static const Color primary = Color(0xFFFF8C42);       // Warm orange
  static const Color primaryLight = Color(0xFFFFBE8A);   // Light peach
  static const Color primaryDark = Color(0xFFE06A1F);    // Deep orange

  // Secondary — soft pink accent
  static const Color secondary = Color(0xFFFFB5C2);     // Soft pink
  static const Color secondaryLight = Color(0xFFFFD9E0); // Light blush

  // Background
  static const Color background = Color(0xFFFFF8F0);    // Cream / warm white
  static const Color surface = Color(0xFFFFFFFF);        // Pure white cards
  static const Color surfaceWarm = Color(0xFFFFF3E8);    // Warm surface

  // Text
  static const Color textPrimary = Color(0xFF3D2C1E);   // Warm dark brown
  static const Color textSecondary = Color(0xFF8B7355);  // Muted brown
  static const Color textHint = Color(0xFFB8A690);       // Light hint

  // Status
  static const Color success = Color(0xFF6BC47F);        // Soft green
  static const Color warning = Color(0xFFFFBB5C);        // Warm amber
  static const Color error = Color(0xFFFF7B7B);          // Soft red
  static const Color info = Color(0xFF7BB8FF);           // Soft blue

  // Companion / pet
  static const Color catOrange = Color(0xFFFFD4A8);      // Cat fur color
  static const Color catOrangeDeep = Color(0xFFE8945A);  // Cat accent
  static const Color moodHappy = Color(0xFFFFE066);      // Happy mood
  static const Color moodNeutral = Color(0xFFB8D4E3);    // Neutral mood
  static const Color expPurple = Color(0xFFD4A5FF);      // EXP color
  static const Color coinGold = Color(0xFFFFD700);       // Coin color
  static const Color fishBlue = Color(0xFF87CEEB);       // Fish treat color

  // UI helpers
  static const Color divider = Color(0xFFF0E6D8);
  static const Color shimmer = Color(0xFFFFF0E0);
  static const Color cardShadow = Color(0x0D3D2C1E);    // 5% brown shadow
}

// ========== Border Radius ==========

class MeowRadius {
  MeowRadius._();

  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double pill = 999.0;

  static BorderRadius get cardRadius => BorderRadius.circular(md);
  static BorderRadius get chipRadius => BorderRadius.circular(pill);
  static BorderRadius get buttonRadius => BorderRadius.circular(sm);
  static BorderRadius get dialogRadius => BorderRadius.circular(xl);
}

// ========== Spacing ==========

class MeowSpacing {
  MeowSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

// ========== Text Styles ==========

class MeowTextStyles {
  MeowTextStyles._();

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: MeowColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: MeowColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: MeowColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: MeowColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: MeowColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: MeowColors.textHint,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: MeowColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle number = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: MeowColors.textPrimary,
    height: 1.2,
  );
}

// ========== Shadows ==========

class MeowShadows {
  MeowShadows._();

  static List<BoxShadow> get card => [
    const BoxShadow(
      color: MeowColors.cardShadow,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardHover => [
    const BoxShadow(
      color: MeowColors.cardShadow,
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get none => [];
}

// ========== ThemeData Builder ==========

class MeowTheme {
  MeowTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: MeowColors.primary,
        brightness: Brightness.light,
        surface: MeowColors.surface,
      ).copyWith(
        primary: MeowColors.primary,
        secondary: MeowColors.secondary,
        error: MeowColors.error,
      ),

      // Scaffold
      scaffoldBackgroundColor: MeowColors.background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: MeowColors.background,
        foregroundColor: MeowColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: MeowColors.textPrimary,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: MeowColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: MeowRadius.cardRadius,
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated buttons (primary CTA)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MeowColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: MeowRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined buttons (secondary)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MeowColors.primary,
          side: const BorderSide(color: MeowColors.primaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: MeowRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MeowColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: MeowColors.surfaceWarm,
        labelStyle: MeowTextStyles.bodySmall,
        shape: RoundedRectangleBorder(
          borderRadius: MeowRadius.chipRadius,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MeowColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: MeowRadius.buttonRadius,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: MeowRadius.dialogRadius,
        ),
        backgroundColor: MeowColors.surface,
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MeowColors.primary,
        linearTrackColor: MeowColors.surfaceWarm,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: MeowColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: MeowColors.textSecondary,
        size: 22,
      ),
    );
  }
}
