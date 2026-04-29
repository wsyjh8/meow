import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// Tab 2 —— 记忆分析
///
/// 完整版（P3 实现）：遗忘曲线双折线 + 词汇等级环形图 + 测试正确率折线。
class MemoryTab extends StatelessWidget {
  const MemoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(SpecSpacing.pageH),
        child: Text(
          '记忆分析 (P3 实现中)',
          style: TextStyle(color: SpecText.secondary, fontSize: 13),
        ),
      ),
    );
  }
}
