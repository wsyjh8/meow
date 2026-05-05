import 'package:flutter/material.dart';

import 'study_tokens.dart';

/// Cream-Café titled-card container shared by every content module on the
/// study page (释义 / 例句 / 近反义词 / 常见词组 / 其他形式 / 词根).
///
/// Visual recipe (Memo1 spec):
///   bg `--card`, radius 22, hairline border `--line`, padding 16/18,
///   shadow soft. Top row: 22×22 cream circle holding an emoji icon +
///   bold caramel title in `Nunito` weight 700.
class SectionFrame extends StatelessWidget {
  final String title;
  final String emoji;
  final Widget body;

  const SectionFrame({
    super.key,
    required this.title,
    required this.emoji,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(
        color: StudyTokens.cardBg,
        borderRadius: BorderRadius.circular(StudyTokens.radiusCard),
        border: Border.all(color: StudyTokens.line, width: 1),
        boxShadow: StudyTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: StudyTokens.cream,
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: StudyTokens.round(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: StudyTokens.main,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );
  }
}
