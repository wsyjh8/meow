import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// 统计页章节卡 — 包裹 fl_chart 图表，提供统一标题 + 副标题 + padding。
///
/// 用法：
/// ```dart
/// StatsChartCard(
///   title: '周/月学习趋势',
///   subtitle: '区分新词与复习',
///   trailing: _granularitySwitch(),
///   height: 200,
///   child: BarChart(...),
/// )
/// ```
class StatsChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final double? height;
  final Widget child;

  /// 卡内左右 padding（默认 18）。柱状/折线图通常需要 18，
  /// 自绘热力图 / 复杂内容可设 0 自定义。
  final double horizontalPadding;

  const StatsChartCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.height,
    required this.child,
    this.horizontalPadding = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 16),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: SpecTypo.medium,
                    color: SpecText.primary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: SpecText.secondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (height != null)
            SizedBox(height: height, child: child)
          else
            child,
        ],
      ),
    );
  }
}
