import 'package:flutter/material.dart';

import 'section_frame.dart';
import 'study_tokens.dart';

/// 释义 — Chinese translation breakdown lines.
///
/// Distinct from the *primary* Chinese meaning shown in
/// [WordHeaderSection]. This module shows the full breakdown lines such
/// as `n. 意外事件, 机遇` derived from `Word.translation`.
///
/// Cream-Café redesign: each line in cocoa ink, generous line-height for
/// the soft-handwritten feel; section card supplies the emoji + label.
class MeaningSection extends StatelessWidget {
  final List<String> lines;

  const MeaningSection({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return SectionFrame(
      title: '释义',
      emoji: '📖',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
              child: Text(
                lines[i],
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: StudyTokens.ink,
                  height: 1.55,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
