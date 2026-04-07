import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// SPEC Section 5.2 — Card Styles
///
/// 4 card types. NO shadows, NO gradients. All values from SPEC.

/// 5.2.1 Filled card (default data card)
/// bg: #F5EFE6, radius: 16, no border
class SpecCardFilled extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const SpecCardFilled({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: SpecBg.card,
        borderRadius: SpecRadius.cardRadius,
      ),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: card);
    return card;
  }
}

/// 5.2.2 Outlined card (secondary info)
/// bg: #FDFBF7, border: 0.5px #E8DFCF, radius: 16
class SpecCardOutlined extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const SpecCardOutlined({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SpecBg.cardOutline,
        border: Border.all(color: SpecBorder.defaultColor, width: SpecBorder.width),
        borderRadius: SpecRadius.cardRadius,
      ),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: card);
    return card;
  }
}

/// 5.2.3 Purple hero card (main CTA / big number)
/// bg: #6B4FA8, radius: 22, white text, supports PawPrint watermark
class SpecCardHero extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showPawPrint;
  final VoidCallback? onTap;

  const SpecCardHero({
    super.key,
    required this.child,
    this.padding,
    this.showPawPrint = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SpecBrand.purple,
        borderRadius: SpecRadius.ctaRadius,
      ),
      child: Stack(
        children: [
          if (showPawPrint)
            const Positioned(
              right: -8,
              bottom: -8,
              child: Opacity(
                opacity: 0.18,
                child: Icon(Icons.pets, size: 80, color: Colors.white),
              ),
            ),
          child,
        ],
      ),
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: card);
    return card;
  }
}

/// 5.2.4 Mochi warm card
/// bg: #FAECE7, radius: 18
class SpecCardMochiWarm extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const SpecCardMochiWarm({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: SpecBg.mochiWarm,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: card);
    return card;
  }
}

/// Stats hero card variant (light purple bg, deep purple text)
/// bg: #EEEDFE, radius: 22
class SpecCardStatsHero extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showPawPrint;

  const SpecCardStatsHero({
    super.key,
    required this.child,
    this.padding,
    this.showPawPrint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SpecBg.heroPurple,
        borderRadius: SpecRadius.ctaRadius,
      ),
      child: Stack(
        children: [
          if (showPawPrint)
            Positioned(
              right: -8,
              bottom: -8,
              child: Opacity(
                opacity: 0.08,
                child: Icon(Icons.pets, size: 80, color: SpecBrand.purple),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
