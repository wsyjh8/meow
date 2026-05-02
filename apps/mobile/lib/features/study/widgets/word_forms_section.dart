import 'package:flutter/material.dart';

import '../../../core/services/word_enrichment_service.dart';
import 'section_frame.dart';
import 'study_tokens.dart';

/// 其他形式 — inflected variants of the word (past / past_participle /
/// present_participle / third_person_singular / plural / comparative /
/// superlative). PRD-mandated naming uses the Chinese label:
/// abandoned (过去式) / abandoning (现在分词) etc.
class WordFormsSection extends StatelessWidget {
  final List<WordFormItem> forms;

  const WordFormsSection({super.key, required this.forms});

  static const Map<String, String> _typeLabel = {
    'past': '过去式',
    'past_participle': '过去分词',
    'present_participle': '现在分词',
    'third_person_singular': '第三人称单数',
    'plural': '复数',
    'comparative': '比较级',
    'superlative': '最高级',
  };

  @override
  Widget build(BuildContext context) {
    if (forms.isEmpty) return const SizedBox.shrink();
    return SectionFrame(
      title: '其他形式',
      body: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: forms.map((f) {
          final label = _typeLabel[f.formType] ?? f.formType;
          return RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: StudyTokens.textDark,
                height: 1.35,
              ),
              children: [
                TextSpan(text: f.formText),
                TextSpan(
                  text: '（$label）',
                  style: const TextStyle(
                    color: StudyTokens.textGray,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
