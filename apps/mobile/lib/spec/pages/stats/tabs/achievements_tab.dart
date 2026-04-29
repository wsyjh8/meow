import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// Tab 4 —— 激励成就
///
/// 完整版（P5 实现）：全球排名占位卡 + 词汇增长预测 + 6 勋章墙。
class AchievementsTab extends StatelessWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(SpecSpacing.pageH),
        child: Text(
          '激励成就 (P5 实现中)',
          style: TextStyle(color: SpecText.secondary, fontSize: 13),
        ),
      ),
    );
  }
}
