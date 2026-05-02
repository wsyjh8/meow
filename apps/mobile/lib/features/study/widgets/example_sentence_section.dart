import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart' show WordExample;
import 'section_frame.dart';
import 'study_tokens.dart';

/// 例句 — up to 2 example sentences for the current word.
///
/// English line is slightly larger (13px / textDark) than the Chinese
/// translation (12px / textGray) — "英主中辅" hierarchy from the
/// typography spec. Brackets used by the source data as highlight
/// markers (`[abandon]`) are stripped for plain rendering.
class ExampleSentenceSection extends StatelessWidget {
  final List<WordExample> examples;

  const ExampleSentenceSection({super.key, required this.examples});

  @override
  Widget build(BuildContext context) {
    if (examples.isEmpty) return const SizedBox.shrink();
    final shown = examples.take(2).toList();
    return SectionFrame(
      title: '例句',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ExampleRow(example: shown[i]),
          ],
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final WordExample example;
  const _ExampleRow({required this.example});

  @override
  Widget build(BuildContext context) {
    final enPlain = example.en.replaceAll(RegExp(r'\[|\]'), '');
    final cnPlain = example.cn.replaceAll(RegExp(r'\[|\]'), '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          enPlain,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: StudyTokens.textDark,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          cnPlain,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: StudyTokens.textGray,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
