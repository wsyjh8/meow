import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart' show Word;
import '../../../core/util/pos_label.dart';
import 'study_tokens.dart';

/// WordTitleCard — the hero card at the top of the study page.
///
/// Cream-Café redesign (Memo1, May 2026): bigger surface, serif word
/// title, kraft-coloured "NO. xxxx" stamp rotated −8° in the top-right
/// corner, IPA + speaker + POS pill on the meta row, full multi-line
/// Chinese meaning beneath. The hero card now owns the meaning content
/// directly (the standalone 释义 section was removed) — `meaningLines`
/// comes from `translationLines(word.translation)` upstream.
class WordHeaderSection extends StatelessWidget {
  final Word word;
  final List<String> meaningLines;
  final bool isPlayingAudio;
  final int todayCompleted;
  final int dailyGoal;
  final Future<void> Function() onSpeakerTap;

  const WordHeaderSection({
    super.key,
    required this.word,
    required this.meaningLines,
    required this.isPlayingAudio,
    required this.todayCompleted,
    required this.dailyGoal,
    required this.onSpeakerTap,
  });

  @override
  Widget build(BuildContext context) {
    final pos = posLabel(word.translation);
    // Stamp number — derive a stable 4-digit code from the word_id so
    // each card looks like a numbered "café receipt". Falls back to today's
    // progress if word_id can't be hashed (shouldn't happen).
    final stampNo = _stampFor(word.wordId, todayCompleted);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: StudyTokens.cardBg,
        borderRadius: BorderRadius.circular(StudyTokens.radiusHero),
        border: Border.all(color: StudyTokens.line, width: 1),
        boxShadow: StudyTokens.shadowCard,
      ),
      child: Stack(
        children: [
          // ── Stamp (top-right, rotated) ─────────────────────────────
          Positioned(
            top: -2,
            right: -4,
            child: Transform.rotate(
              angle: -0.14, // ≈ -8°
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: StudyTokens.main,
                    width: 1.2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'NO.',
                      style: StudyTokens.mono(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: StudyTokens.main,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      stampNo,
                      style: StudyTokens.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: StudyTokens.main,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Main column ────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tiny label "☕ TODAY'S WORD"
              Text(
                "☕ TODAY'S WORD",
                style: StudyTokens.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: StudyTokens.inkSoft,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              // Big serif word
              Padding(
                padding: const EdgeInsets.only(right: 56), // leave room for stamp
                child: Text(
                  word.wordText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StudyTokens.serif(
                    fontSize: 38,
                    fontWeight: FontWeight.w500,
                    color: StudyTokens.ink,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // IPA + speaker + POS pill
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (word.phonetic != null && word.phonetic!.isNotEmpty)
                    Flexible(
                      child: Text(
                        // Wrap with / / so it reads as IPA. Skip if the
                        // source string already carries the slashes.
                        word.phonetic!.startsWith('/')
                            ? word.phonetic!
                            : '/${word.phonetic!}/',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StudyTokens.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: StudyTokens.inkSoft,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  _SpeakerButton(
                    isPlaying: isPlayingAudio,
                    onTap: onSpeakerTap,
                  ),
                  const SizedBox(width: 8),
                  if (pos.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: StudyTokens.cream,
                        borderRadius:
                            BorderRadius.circular(StudyTokens.radiusTag),
                      ),
                      child: Text(
                        pos,
                        style: StudyTokens.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: StudyTokens.main,
                        ),
                      ),
                    ),
                ],
              ),
              if (meaningLines.isNotEmpty) ...[
                const SizedBox(height: 14),
                // Full multi-line Chinese meaning (formerly its own section)
                for (var i = 0; i < meaningLines.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                    child: Text(
                      meaningLines[i],
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: StudyTokens.ink,
                        height: 1.55,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Derive a 4-digit "receipt number" from the word_id. Stable per word so
  // it doesn't flicker on rebuild. Falls back to today's progress if hash
  // somehow returns 0.
  String _stampFor(String wordId, int fallback) {
    final h = wordId.hashCode.abs() % 10000;
    final code = h == 0 ? (fallback % 10000) : h;
    return code.toString().padLeft(4, '0');
  }
}

class _SpeakerButton extends StatelessWidget {
  final bool isPlaying;
  final Future<void> Function() onTap;
  const _SpeakerButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPlaying ? null : () => onTap(),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: StudyTokens.cream,
          shape: BoxShape.circle,
        ),
        child: isPlaying
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: StudyTokens.main,
                ),
              )
            : const Icon(
                Icons.volume_up_rounded,
                size: 15,
                color: StudyTokens.main,
              ),
      ),
    );
  }
}
