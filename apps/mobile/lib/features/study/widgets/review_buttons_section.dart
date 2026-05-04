import 'package:flutter/material.dart';

import '../../../core/memory/review_rating.dart';
import 'study_tokens.dart';

/// 4-button rating row + preview disclaimer line — Cream-Café redesign.
///
/// Rating mapping (FROZEN, P3.3.1): 熟悉 → easy / 认识 → good / 模糊 → hard /
/// 不认识 → again. Sequence and labels are governance-locked and must
/// NOT change here.
///
/// Visual: 4 equal-width pastel buttons, each carrying the Chinese
/// label (PingFang 14/700) above an English mono sub-label (9/400, dim
/// 0.7). Order on screen is the design's left-to-right severity:
/// 不认识 → 模糊 → 认识 → 熟悉. (The legacy code put 熟悉 first; we
/// reverse the visual order to match Memo1 while keeping the mapping
/// intact.)
///
/// preview_durations_reentry_contract_v1 (FROZEN, P3.3.4):
///   `previewDurations` is a local FSRS hint, NOT cloud serving truth.
///   The disclaimer below the row must say "预计间隔（仅供参考）" —
///   forbidden phrasings: "下次将在X天后复习" / "系统已安排" /
///   "已更新计划".
class ReviewButtonsSection extends StatelessWidget {
  final bool enabled;
  final Map<ReviewRating, Duration>? previewDurations;
  final void Function(ReviewRating) onRate;

  const ReviewButtonsSection({
    super.key,
    required this.enabled,
    required this.previewDurations,
    required this.onRate,
  });

  static const List<_StudyBtn> _configs = [
    _StudyBtn(
      label: '不认识',
      sub: 'AGAIN',
      rating: ReviewRating.again,
      palette: StudyTokens.ratingAgain,
    ),
    _StudyBtn(
      label: '模糊',
      sub: 'HARD',
      rating: ReviewRating.hard,
      palette: StudyTokens.ratingHard,
    ),
    _StudyBtn(
      label: '认识',
      sub: 'GOOD',
      rating: ReviewRating.good,
      palette: StudyTokens.ratingGood,
    ),
    _StudyBtn(
      label: '熟悉',
      sub: 'EASY',
      rating: ReviewRating.easy,
      palette: StudyTokens.ratingEasy,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Column(
        children: [
          Row(
            children: _configs.asMap().entries.map((e) {
              final i = e.key;
              final cfg = e.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: _RatingButton(
                    config: cfg,
                    enabled: enabled,
                    onTap: () => onRate(cfg.rating),
                  ),
                ),
              );
            }).toList(),
          ),
          // Need #16 — keep the disclaimer slot reserved so the rating
          // row doesn't shift between cards while previewDurations
          // toggles null↔value. Visibility(maintainSize) keeps the
          // layout stable; the P3.3.4 text contract is unchanged.
          Visibility(
            visible: previewDurations != null,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '预计间隔（仅供参考）',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: StudyTokens.inkSoft.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyBtn {
  final String label;
  final String sub;
  final ReviewRating rating;
  final RatingPalette palette;

  const _StudyBtn({
    required this.label,
    required this.sub,
    required this.rating,
    required this.palette,
  });
}

class _RatingButton extends StatelessWidget {
  final _StudyBtn config;
  final bool enabled;
  final VoidCallback onTap;

  const _RatingButton({
    required this.config,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Need #16 — no opacity animation while _isSubmitting toggles. Tap
    // suppression via onTap=null is sufficient to block double-taps.
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
        decoration: BoxDecoration(
          color: config.palette.bg,
          borderRadius: BorderRadius.circular(StudyTokens.radiusButton),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              config.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: config.palette.fg,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              config.sub,
              style: StudyTokens.mono(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: config.palette.fg.withValues(alpha: 0.7),
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
