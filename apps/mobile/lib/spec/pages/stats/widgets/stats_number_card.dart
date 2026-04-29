import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// 统计页通用数字卡：label + 大号数字 + unit + (optional) 副文字。
///
/// 例：
/// ```
/// 累计词汇量
/// 2485
/// ↑ 较上周 +120
/// ```
class StatsNumberCard extends StatelessWidget {
  final String label;
  final String number;
  final String? unit;
  final String? subtitle;
  final Color numberColor;

  const StatsNumberCard({
    super.key,
    required this.label,
    required this.number,
    this.unit,
    this.subtitle,
    this.numberColor = SpecText.purpleDeep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: SpecRadius.cardRadius,
        border: Border.all(
          color: SpecBorder.defaultColor,
          width: SpecBorder.width,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: SpecText.secondary),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: number,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: SpecTypo.medium,
                    color: numberColor,
                  ),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 11,
                      color: SpecText.tertiary,
                    ),
                  ),
              ],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: SpecText.coral,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
