import 'package:flutter/material.dart';

import '../../../core/services/word_enrichment_service.dart';
import 'section_frame.dart';
import 'study_tokens.dart';

/// 词根词缀参考 (Need #12) — Heuristic morpheme breakdown.
///
/// Title intentionally hedges with "参考" (= "reference") because the
/// underlying matches are heuristic prefix/suffix boundary detection,
/// not strict etymological proof. Avoid wording like "由 X 组成" so we
/// don't promote a guess into an assertion.
class WordMorphemesSection extends StatelessWidget {
  final List<MorphemeMatch> morphemes;

  const WordMorphemesSection({super.key, required this.morphemes});

  static const Map<String, String> _typeLabel = {
    'prefix': '前缀',
    'suffix': '后缀',
    'root_or_stem': '词根',
  };

  @override
  Widget build(BuildContext context) {
    if (morphemes.isEmpty) return const SizedBox.shrink();
    return SectionFrame(
      title: '词根词缀参考',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < morphemes.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            _MorphemeRow(match: morphemes[i]),
          ],
        ],
      ),
    );
  }
}

class _MorphemeRow extends StatelessWidget {
  final MorphemeMatch match;
  const _MorphemeRow({required this.match});

  @override
  Widget build(BuildContext context) {
    final typeLabel =
        WordMorphemesSection._typeLabel[match.morphemeType] ?? match.morphemeType;
    final meaningText =
        match.meanings.isEmpty ? '—' : match.meanings.join(', ');
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: StudyTokens.textDark,
          height: 1.35,
        ),
        children: [
          TextSpan(text: match.morpheme),
          TextSpan(
            text: '（$typeLabel）',
            style: const TextStyle(
              color: StudyTokens.textGray,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
          const TextSpan(text: '：'),
          TextSpan(text: meaningText),
        ],
      ),
    );
  }
}
