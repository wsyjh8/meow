import 'package:flutter/material.dart';
import '../theme.dart';

/// MeowChip — Lightweight status tag / pill label.
///
/// Used for: level, mood, owned, equipped, locked, resource amounts, etc.
enum MeowChipVariant {
  neutral,   // Default grey/warm
  primary,   // Orange
  success,   // Green
  warning,   // Amber
  info,      // Blue
  accent,    // Pink
  purple,    // EXP
}

class MeowChip extends StatelessWidget {
  const MeowChip({
    super.key,
    required this.label,
    this.icon,
    this.variant = MeowChipVariant.neutral,
    this.small = false,
  });

  final String label;
  final IconData? icon;
  final MeowChipVariant variant;
  final bool small;

  Color get _backgroundColor {
    switch (variant) {
      case MeowChipVariant.primary:
        return MeowColors.primaryLight.withValues(alpha: 0.3);
      case MeowChipVariant.success:
        return MeowColors.success.withValues(alpha: 0.15);
      case MeowChipVariant.warning:
        return MeowColors.warning.withValues(alpha: 0.2);
      case MeowChipVariant.info:
        return MeowColors.info.withValues(alpha: 0.15);
      case MeowChipVariant.accent:
        return MeowColors.secondary.withValues(alpha: 0.3);
      case MeowChipVariant.purple:
        return MeowColors.expPurple.withValues(alpha: 0.2);
      case MeowChipVariant.neutral:
        return MeowColors.surfaceWarm;
    }
  }

  Color get _foregroundColor {
    switch (variant) {
      case MeowChipVariant.primary:
        return MeowColors.primaryDark;
      case MeowChipVariant.success:
        return const Color(0xFF2D8F4E);
      case MeowChipVariant.warning:
        return const Color(0xFFB8860B);
      case MeowChipVariant.info:
        return const Color(0xFF2E6BB0);
      case MeowChipVariant.accent:
        return const Color(0xFFC0547A);
      case MeowChipVariant.purple:
        return const Color(0xFF7B4BB3);
      case MeowChipVariant.neutral:
        return MeowColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = small ? 11.0 : 12.0;
    final hPad = small ? 8.0 : 10.0;
    final vPad = small ? 3.0 : 5.0;
    final iconSize = small ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: MeowRadius.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: _foregroundColor),
            SizedBox(width: small ? 3 : 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
