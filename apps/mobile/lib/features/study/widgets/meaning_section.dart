import 'package:flutter/material.dart';

import 'section_frame.dart';
import 'study_tokens.dart';

/// 释义 — Chinese translation breakdown lines.
///
/// Distinct from the *primary* Chinese meaning shown in
/// [WordHeaderSection] (the bold 15px text next to the POS pill).
/// This module shows the full breakdown lines such as
/// `n. 意外事件, 机遇` / `[经] 意外事故, 事故` derived from
/// `Word.translation` via the project's `translationLines` helper.
class MeaningSection extends StatelessWidget {
  final List<String> lines;

  const MeaningSection({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return SectionFrame(
      title: '释义',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: StudyTokens.textMedium,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
