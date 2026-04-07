import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// SPEC Section 5.3 — Settings List Group
///
/// Outlined container with divider-separated rows.
/// border: 0.5px #E8DFCF, bg: #FDFBF7, radius: 16.
/// Each row: padding 13px 14px, 13px font, space-between.

/// Group label above the list
class SpecSettingsGroupLabel extends StatelessWidget {
  final String text;
  const SpecSettingsGroupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: SpecTypo.regular,
          color: SpecText.tertiary,
        ),
      ),
    );
  }
}

/// The settings group container
class SpecSettingsGroup extends StatelessWidget {
  final List<SpecSettingsRow> rows;
  const SpecSettingsGroup({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: SpecBg.cardOutline,
        border: Border.all(color: SpecBorder.defaultColor, width: SpecBorder.width),
        borderRadius: SpecRadius.cardRadius,
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                color: SpecBorder.divider,
                indent: 14,
                endIndent: 14,
              ),
          ],
        ],
      ),
    );
  }
}

/// A single settings row
class SpecSettingsRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool showChevron;
  final VoidCallback? onTap;
  final Color? valueColor;
  final FontWeight? valueWeight;

  const SpecSettingsRow({
    super.key,
    required this.label,
    this.value,
    this.showChevron = true,
    this.onTap,
    this.valueColor,
    this.valueWeight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: SpecSpacing.minTouch),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: SpecTypo.regular,
                color: SpecText.primary,
              ),
            ),
            const Spacer(),
            if (value != null)
              Padding(
                padding: EdgeInsets.only(right: showChevron ? 6 : 0),
                child: Text(
                  value!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: valueWeight ?? SpecTypo.regular,
                    color: valueColor ?? SpecText.secondary,
                  ),
                ),
              ),
            if (showChevron)
              const Icon(Icons.chevron_right, size: 16, color: SpecText.tertiary),
          ],
        ),
      ),
    );
  }
}
