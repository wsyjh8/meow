import 'package:flutter/material.dart';

import 'study_tokens.dart';

/// CatCompanionStrip — emotional-companion row above the rating buttons.
///
/// Cream-Café spec: a small mascot circle on the left + a soft prompt
/// line ("Momo 等着你的答案～"). The mascot here is a placeholder
/// (orange-cream emoji circle). Replace with the brand mascot SVG /
/// Lottie once art is ready — see Memo1 README §Assets.
///
/// The strip carries no business effect — purely emotional pacing.
class CatCompanionStrip extends StatelessWidget {
  final String message;

  const CatCompanionStrip({
    super.key,
    this.message = 'Momo 在等你的答案～',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
      child: Row(
        children: [
          // Mascot placeholder — orange-cream circle with cat emoji.
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StudyTokens.cream,
              shape: BoxShape.circle,
              border: Border.all(
                color: StudyTokens.main.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: const Text('🐱', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: StudyTokens.inkSoft,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
