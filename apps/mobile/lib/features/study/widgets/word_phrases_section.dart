import 'package:flutter/material.dart';

import 'section_frame.dart';
import 'study_tokens.dart';

/// 常见词组 — list of common phrases.
///
/// Cream-Café spec: each row is space-between (English serif on the
/// left, optional translation hint on the right) separated by a 1px
/// dashed line. Our enrichment service stores phrases as plain strings
/// (no translation), so we render the whole string on the left only.
class WordPhrasesSection extends StatelessWidget {
  final List<String> phrases;

  const WordPhrasesSection({super.key, required this.phrases});

  @override
  Widget build(BuildContext context) {
    if (phrases.isEmpty) return const SizedBox.shrink();
    return SectionFrame(
      title: '常见词组',
      emoji: '🧩',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < phrases.length; i++) ...[
            if (i > 0) const _DashedRow(),
            Padding(
              padding:
                  EdgeInsets.symmetric(vertical: i == 0 ? 0 : 8),
              child: Text(
                phrases[i],
                style: StudyTokens.serif(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: StudyTokens.ink,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashedRow extends StatelessWidget {
  const _DashedRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CustomPaint(
        painter: _DashedLinePainter(),
        size: const Size(double.infinity, 1),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 3.0;
    const dashGap = 3.0;
    final paint = Paint()
      ..color = StudyTokens.line
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
