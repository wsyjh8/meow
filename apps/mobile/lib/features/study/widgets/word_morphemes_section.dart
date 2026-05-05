import 'package:flutter/material.dart';

import '../../../core/services/word_enrichment_service.dart';
import 'section_frame.dart';
import 'study_tokens.dart';

/// 词根词缀参考 (Need #12) — heuristic morpheme breakdown.
///
/// Title hedges with "参考" because matches are heuristic prefix/suffix
/// detection, not strict etymological proof. Cream-Café renders each
/// row inside the section card with a small mono "PRE/SUF/ROOT" label
/// pill, the morpheme in serif, then the gloss.
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
      emoji: '🌱',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < morphemes.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          margin: const EdgeInsets.only(top: 2, right: 8),
          decoration: BoxDecoration(
            color: StudyTokens.cream,
            borderRadius: BorderRadius.circular(StudyTokens.radiusTag),
          ),
          child: Text(
            typeLabel,
            style: StudyTokens.mono(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: StudyTokens.main,
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: StudyTokens.serif(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: StudyTokens.ink,
                height: 1.45,
              ),
              children: [
                TextSpan(text: match.morpheme),
                const TextSpan(
                  text: '  ·  ',
                  style: TextStyle(color: StudyTokens.inkSoft),
                ),
                TextSpan(
                  text: meaningText,
                  style: const TextStyle(
                    color: StudyTokens.inkSoft,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
