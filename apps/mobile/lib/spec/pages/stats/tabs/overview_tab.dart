import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// Tab 1 —— 概览趋势
///
/// 完整版（P2 实现）：4 数字卡 + 周/月趋势柱状 + 24h 活跃折线 + 365 热力图。
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(SpecSpacing.pageH),
        child: Text(
          '概览趋势 (P2 实现中)',
          style: TextStyle(color: SpecText.secondary, fontSize: 13),
        ),
      ),
    );
  }
}
