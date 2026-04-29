import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

/// 数据不足时的空态展示。
///
/// 文案温柔（项目硬纪律：温柔体验，避免愧疚）。
class StatsEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const StatsEmptyState({
    super.key,
    this.message = '再学几天，这里会有惊喜',
    this.icon = Icons.auto_awesome_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: SpecText.tertiary),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: SpecText.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
