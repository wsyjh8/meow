import 'package:flutter/material.dart';

import '../../../core/memory/review_rating.dart';
import 'study_tokens.dart';

/// 4-button rating row + preview disclaimer line.
///
/// Rating mapping (FROZEN): 熟悉 → easy / 认识 → good / 模糊 → hard /
/// 不认识 → again. Sequence and labels are governance-locked
/// (P3.3.1) and must NOT change here.
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
      label: '熟悉',
      rating: ReviewRating.easy,
      bgColor: StudyTokens.purple,
      borderColor: StudyTokens.purple,
      textColor: Colors.white,
      hasTick: true,
    ),
    _StudyBtn(
      label: '认识',
      rating: ReviewRating.good,
      bgColor: StudyTokens.softPurpleBg,
      borderColor: StudyTokens.purpleBorder,
      textColor: StudyTokens.purple,
    ),
    _StudyBtn(
      label: '模糊',
      rating: ReviewRating.hard,
      bgColor: StudyTokens.orangeBg,
      borderColor: StudyTokens.orangeBorder,
      textColor: StudyTokens.orangeText,
    ),
    _StudyBtn(
      label: '不认识',
      rating: ReviewRating.again,
      bgColor: StudyTokens.neutralBg,
      borderColor: StudyTokens.neutralBorder,
      textColor: StudyTokens.neutralText,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
          // Need #16 — always reserve disclaimer space so the rating row
          // doesn't shift between cards while previewDurations toggles
          // null↔value (cleared synchronously on tap, repopulated async
          // by FsrsService.previewSchedule). Visibility(maintainSize)
          // keeps the layout stable; the P3.3.4 text contract is
          // unchanged — only its visibility is gated.
          Visibility(
            visible: previewDurations != null,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '预计间隔（仅供参考）',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Button config for one slot in the 4-button rating row.
class _StudyBtn {
  final String label;
  final ReviewRating rating;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final bool hasTick;

  const _StudyBtn({
    required this.label,
    required this.rating,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    this.hasTick = false,
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
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: config.bgColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: config.borderColor, width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                config.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: config.textColor,
                ),
              ),
              if (config.hasTick) ...[
                const SizedBox(width: 3),
                Icon(Icons.check_rounded, size: 12, color: config.textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
