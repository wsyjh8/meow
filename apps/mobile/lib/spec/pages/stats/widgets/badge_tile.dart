import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../models/stats_models.dart';

/// 勋章卡：已解锁高亮 + 表情图标；未解锁灰显 + 进度条。
class BadgeTile extends StatelessWidget {
  final BadgeStatus badge;

  /// 解锁时显示的 emoji（外部传入便于风格统一）
  final String emoji;

  /// 已解锁的卡背景色（柔和的）
  final Color unlockedBg;

  const BadgeTile({
    super.key,
    required this.badge,
    required this.emoji,
    this.unlockedBg = const Color(0xFFFCE9D8), // 柔和的米黄
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = badge.unlocked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: unlocked ? unlockedBg : SpecBg.card,
        borderRadius: SpecRadius.cardRadius,
        border: Border.all(
          color: unlocked ? unlockedBg : SpecBorder.defaultColor,
          width: SpecBorder.width,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: unlocked ? 1.0 : 0.35,
            child: Text(emoji, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 6),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: SpecTypo.medium,
              color: unlocked ? SpecText.primary : SpecText.tertiary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            badge.desc,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: SpecText.tertiary,
              height: 1.3,
            ),
          ),
          if (!unlocked && badge.progress > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: badge.progress,
                minHeight: 3,
                backgroundColor: SpecBorder.divider,
                valueColor: const AlwaysStoppedAnimation(SpecBrand.purple),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
