import 'package:flutter/material.dart';

import '../../../core/services/word_enrichment_service.dart';
import 'section_frame.dart';
import 'study_tokens.dart';

/// 其他形式 — inflected variants in a 2-column cream grid.
///
/// Cream-Café spec: `display: grid; grid-template-columns: 1fr 1fr; gap: 8`
/// — small cream cards holding a label (10px ink-soft) above the form
/// (Fraunces 13.5/500). PRD-mandated naming uses Chinese type labels.
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
      emoji: '🔀',
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Two equal-width columns with 8px gap.
          const gap = 8.0;
          final cellWidth = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: forms.map((f) {
              final label = _typeLabel[f.formType] ?? f.formType;
              return SizedBox(
                width: cellWidth,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: StudyTokens.cream,
                    borderRadius:
                        BorderRadius.circular(StudyTokens.radiusPill),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: StudyTokens.inkSoft,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f.formText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StudyTokens.serif(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: StudyTokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
