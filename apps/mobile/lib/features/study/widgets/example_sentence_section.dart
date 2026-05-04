import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart' show WordExample;
import 'section_frame.dart';
import 'study_tokens.dart';

/// 例句 — up to 2 example sentences for the current word.
///
/// Cream-Café spec: English in italic Fraunces (15 / 1.55), Chinese in
/// 13/ink-soft. Examples are separated by a 1px dashed cream-line
/// divider with 12px vertical padding to give the "handwritten journal"
/// feel.
class ExampleSentenceSection extends StatelessWidget {
  final List<WordExample> examples;

  const ExampleSentenceSection({super.key, required this.examples});

  @override
  Widget build(BuildContext context) {
    if (examples.isEmpty) return const SizedBox.shrink();
    final shown = examples.take(2).toList();
    return SectionFrame(
      title: '例句',
      emoji: '✍️',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) const _DashedDivider(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: i == 0 ? 0 : 10),
              child: _ExampleRow(example: shown[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final WordExample example;
  const _ExampleRow({required this.example});

  @override
  Widget build(BuildContext context) {
    final enPlain = example.en.replaceAll(RegExp(r'\[|\]'), '');
    final cnPlain = example.cn.replaceAll(RegExp(r'\[|\]'), '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          enPlain,
          style: StudyTokens.serif(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: StudyTokens.ink,
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          cnPlain,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: StudyTokens.inkSoft,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
