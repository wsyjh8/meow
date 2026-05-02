import 'package:flutter/material.dart';

import 'study_tokens.dart';

/// Generic titled-block container shared by every content module
/// inside the study card (释义 / 例句 / 其他形式 / 近反义词 /
/// 常见词组 / 词根词缀参考).
///
/// Title styling is intentionally small + gray + tracked so it reads
/// as a quiet section label, not as a heading that competes with the
/// primary meaning row at the top of the card.
class SectionFrame extends StatelessWidget {
  final String title;
  final Widget body;

  const SectionFrame({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: StudyTokens.textGray,
            letterSpacing: 0.4,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        body,
      ],
    );
  }
}
