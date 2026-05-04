import 'package:flutter/material.dart';

import 'section_frame.dart';
import 'study_tokens.dart';

/// 近反义词 — synonyms (mint chips) + antonyms (peach chips).
///
/// Cream-Café spec: each row has a small mono "SYN +" / "ANT −" label
/// in success / accent colour, followed by inline pill chips. The whole
/// section hides if both lists are empty; either list may be empty
/// independently.
class WordRelationsSection extends StatelessWidget {
  final List<String> synonyms;
  final List<String> antonyms;

  const WordRelationsSection({
    super.key,
    required this.synonyms,
    required this.antonyms,
  });

  @override
  Widget build(BuildContext context) {
    if (synonyms.isEmpty && antonyms.isEmpty) {
      return const SizedBox.shrink();
    }
    return SectionFrame(
      title: '近反义词',
      emoji: '🔄',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (synonyms.isNotEmpty)
            _RelationRow(
              label: 'SYN +',
              labelColor: StudyTokens.success,
              chipBg: StudyTokens.greenBg,
              chipFg: StudyTokens.greenText,
              items: synonyms,
            ),
          if (synonyms.isNotEmpty && antonyms.isNotEmpty)
            const SizedBox(height: 8),
          if (antonyms.isNotEmpty)
            _RelationRow(
              label: 'ANT −',
              labelColor: StudyTokens.accent,
              chipBg: StudyTokens.orangeBg,
              chipFg: StudyTokens.orangeText,
              items: antonyms,
            ),
        ],
      ),
    );
  }
}

class _RelationRow extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Color chipBg;
  final Color chipFg;
  final List<String> items;

  const _RelationRow({
    required this.label,
    required this.labelColor,
    required this.chipBg,
    required this.chipFg,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 8),
          child: Text(
            label,
            style: StudyTokens.mono(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: labelColor,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((w) => _Chip(text: w, bg: chipBg, fg: chipFg))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Chip({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        text,
        style: StudyTokens.serif(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
