import 'package:flutter/material.dart';
import '../theme.dart';

/// ResourceBadge — Compact resource display (coins, fish treats, exp).
///
/// For use in resource bars and summary cards.
class ResourceBadge extends StatelessWidget {
  const ResourceBadge({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.label,
    this.compact = false,
  });

  final IconData icon;
  final String value;
  final Color color;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MeowSpacing.md,
        vertical: MeowSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: MeowRadius.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: MeowSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: MeowTextStyles.caption.copyWith(color: color.withValues(alpha: 0.7)),
                ),
              Text(
                value,
                style: MeowTextStyles.label.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: MeowColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
