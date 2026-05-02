import 'package:flutter/material.dart';

/// Visual tokens for the study card. **Public** so Section widgets in
/// neighboring files can reference them — Dart enforces underscore-
/// prefixed names as library-private and they cannot be imported, so
/// the legacy `_kXxx` constants in `study_page.dart` had to graduate to
/// this class for the v2 component-extraction refactor (Need #14).
///
/// Names mirror the legacy `_kXxx` constants 1:1 so a port-by-replace
/// is mechanically safe.
class StudyTokens {
  StudyTokens._();

  static const Color bg = Color(0xFFF5F1EA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color purple = Color(0xFF6B4FA8);
  static const Color softPurpleBg = Color(0xFFF2EFFA);
  static const Color purpleBorder = Color(0xFFB8A8D4);
  static const Color orangeBg = Color(0xFFFAECE7);
  static const Color orangeBorder = Color(0xFFF0D4C0);
  static const Color orangeText = Color(0xFFA68872);
  static const Color neutralBg = Color(0xFFFDFBF7);
  static const Color neutralBorder = Color(0xFFE8E2D8);
  static const Color neutralText = Color(0xFF5C554C);
  static const Color textDark = Color(0xFF2C2C2A);
  static const Color textGray = Color(0xFF9C948A);
  static const Color textMedium = Color(0xFF5C554C);
  static const Color borderColor = Color(0xFFEFEBE4);
  static const Color progressBg = Color(0xFFEFEBE4);
  static const Color greenBg = Color(0xFFE8F2ED);
  static const Color greenText = Color(0xFF3F7A5F);
  static const Color barBg = Color(0xFFB8B0A4);
}
