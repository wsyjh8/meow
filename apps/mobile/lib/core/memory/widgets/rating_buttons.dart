import 'package:flutter/material.dart';

import '../review_rating.dart';

/// Rating button configuration.
///
/// Defines the visual and semantic properties for each rating option.
/// Centralizing this makes it easy to switch between 3-button and 4-button
/// configurations — only this file needs to change.
///
/// ## Switching from 4 buttons to 3 buttons
///
/// If you want to reduce to 3 buttons (e.g., drop "Hard" and keep
/// Again/Good/Easy), you need to change ONLY these files:
///
/// 1. **This file** (`rating_buttons.dart`):
///    - Remove the `hard` entry from [defaultRatingConfigs]
///    - (Optional) Adjust label text for remaining buttons
///
/// 2. **`review_rating.dart`**:
///    - Remove `ReviewRating.hard` from the enum
///    - Update the doc comment
///
/// 3. **`fsrs_service.dart`**:
///    - Remove the `ReviewRating.hard` case from `_toFsrsRating()`
///    - In `previewSchedule()`, the loop uses `ReviewRating.values`
///      so it auto-adjusts
///
/// 4. **`FSRS_DESIGN_DRAFT.md`**:
///    - Update the rating mapping table
///
/// NO other files need to change — rateCard(), review_logs schema,
/// card_states schema, session_builder are all rating-count agnostic.
class RatingButtonConfig {
  final ReviewRating rating;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final Color textColor;

  const RatingButtonConfig({
    required this.rating,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.textColor,
  });
}

/// Default 4-button configuration.
///
/// Order: Again → Hard → Good → Easy (left to right).
/// Colors use warm tones aligned with SPEC design system.
/// Each button has both an icon and text label (色盲友好).
const List<RatingButtonConfig> defaultRatingConfigs = [
  RatingButtonConfig(
    rating: ReviewRating.again,
    label: '不认识',
    sublabel: '重来',
    icon: Icons.refresh_rounded,
    color: Color(0xFFE8564A), // warm red
    textColor: Colors.white,
  ),
  RatingButtonConfig(
    rating: ReviewRating.hard,
    label: '模糊',
    sublabel: '有点印象',
    icon: Icons.cloud_outlined,
    color: Color(0xFFE8A54A), // warm orange
    textColor: Colors.white,
  ),
  RatingButtonConfig(
    rating: ReviewRating.good,
    label: '记得',
    sublabel: '想了一下',
    icon: Icons.check_rounded,
    color: Color(0xFF6B4FA8), // brand purple
    textColor: Colors.white,
  ),
  RatingButtonConfig(
    rating: ReviewRating.easy,
    label: '秒答',
    sublabel: '很简单',
    icon: Icons.bolt_rounded,
    color: Color(0xFF3D9970), // calm green
    textColor: Colors.white,
  ),
];

/// FSRS rating button bar widget.
///
/// Displays 4 (or 3) rating buttons with optional interval preview.
/// UI layer calls [onRate] with a [ReviewRating]; it does NOT know
/// about the fsrs library.
///
/// [previewDurations]: if provided, shows "下次: X" below each button.
/// This comes from FsrsService.previewSchedule().
class FsrsRatingButtons extends StatelessWidget {
  final void Function(ReviewRating rating) onRate;
  final bool enabled;
  final Map<ReviewRating, Duration>? previewDurations;
  final List<RatingButtonConfig> configs;

  const FsrsRatingButtons({
    super.key,
    required this.onRate,
    this.enabled = true,
    this.previewDurations,
    this.configs = defaultRatingConfigs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: configs.asMap().entries.map((entry) {
        final i = entry.key;
        final config = entry.value;
        final preview = previewDurations?[config.rating];

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 4,
              right: i == configs.length - 1 ? 0 : 4,
            ),
            child: _RatingButton(
              config: config,
              preview: preview,
              enabled: enabled,
              onTap: () => onRate(config.rating),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final RatingButtonConfig config;
  final Duration? preview;
  final bool enabled;
  final VoidCallback onTap;

  const _RatingButton({
    required this.config,
    this.preview,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? config.color : config.color.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon (色盲友好 — 不只靠颜色区分)
              Icon(config.icon, color: config.textColor, size: 22),
              const SizedBox(height: 4),
              // Main label
              Text(
                config.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: config.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              // Preview interval
              if (preview != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatPreview(preview!),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: config.textColor.withValues(alpha: 0.75),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Format a duration into a short human-readable label.
  /// Examples: "1分钟", "10分钟", "1天", "3天", "2周", "1月"
  String _formatPreview(Duration d) {
    if (d.inDays >= 30) {
      final months = (d.inDays / 30).round();
      return '$months月';
    } else if (d.inDays >= 7) {
      final weeks = (d.inDays / 7).round();
      return '$weeks周';
    } else if (d.inDays >= 1) {
      return '${d.inDays}天';
    } else if (d.inMinutes >= 1) {
      return '${d.inMinutes}分钟';
    } else {
      return '<1分钟';
    }
  }
}
