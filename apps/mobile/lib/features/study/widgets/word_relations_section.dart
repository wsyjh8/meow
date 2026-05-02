import 'package:flutter/material.dart';

import 'section_frame.dart';
import 'study_tokens.dart';

/// 近反义词 — synonyms and antonyms in two labelled rows.
///
/// The whole section hides if both lists are empty. Either list may
/// be empty independently — only the present row(s) render.
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (synonyms.isNotEmpty)
            _RelationRow(label: '近义词', items: synonyms),
          if (synonyms.isNotEmpty && antonyms.isNotEmpty)
            const SizedBox(height: 4),
          if (antonyms.isNotEmpty)
            _RelationRow(label: '反义词', items: antonyms),
        ],
      ),
    );
  }
}

class _RelationRow extends StatelessWidget {
  final String label;
  final List<String> items;
  const _RelationRow({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: StudyTokens.textDark,
          height: 1.35,
        ),
        children: [
          TextSpan(
            text: '$label：',
            style: const TextStyle(
              color: StudyTokens.textGray,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          TextSpan(text: items.join(', ')),
        ],
      ),
    );
  }
}
