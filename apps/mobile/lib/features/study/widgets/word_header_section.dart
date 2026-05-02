import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart' show Word;
import '../../../core/util/pos_label.dart';
import 'study_tokens.dart';

/// Fixed-height card-top region.
///
/// Holds the word's identity-defining information: status badges, the
/// English word + phonetic + speaker button, the POS pill, and the
/// primary Chinese meaning ("意外事件"). PRD #14 requires this region
/// to **never scroll** and to **never grow** — so:
///
/// * Outermost wrapper is `SizedBox(height: 156)` (strict fixed height).
/// * Word / phonetic / POS pill use `maxLines: 1` + ellipsis.
/// * Primary meaning uses `maxLines: 2` + ellipsis (some CET-4 entries
///   pack ~30 Chinese chars).
///
/// Tokens like the orange speaker button and POS pill geometry are
/// preserved verbatim from the previous inline implementation; only
/// the wrapper structure (SizedBox + ellipsis) is new.
class WordHeaderSection extends StatelessWidget {
  static const double fixedHeight = 156;

  final Word word;
  final bool isPlayingAudio;
  final int todayCompleted;
  final int dailyGoal;
  final Future<void> Function() onSpeakerTap;

  const WordHeaderSection({
    super.key,
    required this.word,
    required this.isPlayingAudio,
    required this.todayCompleted,
    required this.dailyGoal,
    required this.onSpeakerTap,
  });

  @override
  Widget build(BuildContext context) {
    final pos = posLabel(word.translation);

    return SizedBox(
      height: fixedHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badge row ───────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CatMoodBadge(completed: todayCompleted, goal: dailyGoal),
              const _WordTypeBadge(label: '新词'),
            ],
          ),
          const SizedBox(height: 10),

          // ── Word + phonetic + speaker ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.wordText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: StudyTokens.textDark,
                        letterSpacing: 0.3,
                        height: 1.15,
                      ),
                    ),
                    if (word.phonetic != null && word.phonetic!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          word.phonetic!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: StudyTokens.textGray,
                            height: 1.25,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _SpeakerButton(
                isPlaying: isPlayingAudio,
                onTap: onSpeakerTap,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── POS pill + primary meaning ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (pos.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    color: StudyTokens.softPurpleBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    pos,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: StudyTokens.purple,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  word.meaning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: StudyTokens.textDark,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Badges (private to this file) ──────────────────────────────────────

/// Mood-state pill on the left. Tracks today_new_completed / daily_goal
/// and shifts emoji + copy at fixed thresholds. Visual only — no
/// business effect.
class _CatMoodBadge extends StatelessWidget {
  final int completed;
  final int goal;
  const _CatMoodBadge({required this.completed, required this.goal});

  @override
  Widget build(BuildContext context) {
    final ratio = goal > 0 ? completed / goal : 0.0;
    final (emoji, mood) = ratio >= 0.7
        ? ('😸', '状态很棒')
        : ratio >= 0.3
            ? ('😺', '不错加油')
            : ('🐱', '今日状态稳定');

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFAECE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            mood,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFFA68872),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordTypeBadge extends StatelessWidget {
  final String label;
  const _WordTypeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: StudyTokens.greenBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: StudyTokens.greenText,
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 11),
        decoration: BoxDecoration(
          color: StudyTokens.orangeBg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: isPlaying
            ? const SizedBox(
                width: 38,
                height: 14,
                child: Center(
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: StudyTokens.orangeText,
                    ),
                  ),
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up_outlined,
                      size: 14, color: StudyTokens.orangeText),
                  SizedBox(width: 4),
                  Text('发音',
                      style: TextStyle(
                          fontSize: 10, color: StudyTokens.orangeText)),
                ],
              ),
      ),
    );
  }
}
