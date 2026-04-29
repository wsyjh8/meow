import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// Tab 3 —— 重点难点
///
/// 完整版（P4 实现）：顽固词 Top10 表 + 词性雷达图 + 一键强化复习按钮。
class KeyPointsTab extends StatelessWidget {
  const KeyPointsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(SpecSpacing.pageH),
        child: Text(
          '重点难点 (P4 实现中)',
          style: TextStyle(color: SpecText.secondary, fontSize: 13),
        ),
      ),
    );
  }
}
