import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// 「回到学习」chip — 放置在副机制页右上角。
///
/// 规格（design-tokens.md §「回到学习」chip）：
/// - 高 30px，padding 0 12px，圆角 999
/// - 浅色：bg rgba(107,79,168,0.08)，border rgba(107,79,168,0.2)，紫色文字 11/w500
/// - 深色：bg rgba(255,255,255,0.12)，border rgba(255,255,255,0.18)，白色文字 11/w500
/// - 点击跳 /study
class SpecBackToStudyChip extends StatelessWidget {
  const SpecBackToStudyChip({super.key, this.dark = false});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/study'),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: dark ? const Color(0x1EFFFFFF) : const Color(0x146B4FA8),
          border: Border.all(
            color: dark ? const Color(0x2DFFFFFF) : const Color(0x336B4FA8),
            width: 0.5,
          ),
          borderRadius: SpecRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📖', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              '回到学习',
              style: TextStyle(
                fontSize: 11,
                fontWeight: SpecTypo.medium,
                color: dark ? Colors.white : SpecBrand.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
