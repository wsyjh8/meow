import 'package:flutter/material.dart';
import '../theme.dart';

/// MeowCard — Unified rounded card for all pages.
///
/// Soft shadow, warm background, consistent padding and radius.
/// Use across Meow Home, Today, Customize.
class MeowCard extends StatelessWidget {
  const MeowCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.margin,
    this.onTap,
    this.hasShadow = true,
    this.borderColor,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool hasShadow;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.only(bottom: MeowSpacing.md),
      decoration: BoxDecoration(
        color: color ?? MeowColors.surface,
        borderRadius: MeowRadius.cardRadius,
        boxShadow: hasShadow ? MeowShadows.card : MeowShadows.none,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(MeowSpacing.lg),
        child: child,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}

/// MeowCardWarm — Warm-tinted variant for companion/pet areas.
class MeowCardWarm extends StatelessWidget {
  const MeowCardWarm({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return MeowCard(
      color: MeowColors.surfaceWarm,
      borderColor: MeowColors.primaryLight.withValues(alpha: 0.3),
      hasShadow: false,
      padding: padding,
      margin: margin,
      child: child,
    );
  }
}
