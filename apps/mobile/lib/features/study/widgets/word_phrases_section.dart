import 'package:flutter/material.dart';

import 'section_frame.dart';
import 'study_tokens.dart';

/// 常见词组 — chip-style list of phrases.
///
/// Chip min height ≥ 28: fontSize 12 × height 1.2 ≈ 14.4 line-box +
/// 7 vertical padding × 2 ≈ 28.4 (matches typography spec).
class WordPhrasesSection extends StatelessWidget {
  final List<String> phrases;

  const WordPhrasesSection({super.key, required this.phrases});

  @override
  Widget build(BuildContext context) {
    if (phrases.isEmpty) return const SizedBox.shrink();
    return SectionFrame(
      title: '常见词组',
      body: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: phrases.map((p) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: StudyTokens.neutralBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: StudyTokens.neutralBorder, width: 0.5),
            ),
            child: Text(
              p,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: StudyTokens.neutralText,
                height: 1.2,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
