import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// SPEC Section 4.1 — Mochi Large Illustration (200×210 viewBox)
/// Used as page visual center on Mochi page.
/// DO NOT modify Mochi's character palette.
class MochiLarge extends StatelessWidget {
  final double width;
  const MochiLarge({super.key, this.width = 200});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 210 / 200),
      painter: _MochiLargePainter(),
    );
  }
}

class _MochiLargePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 200;

    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(100 * s, 195 * s), width: 140 * s, height: 12 * s),
      Paint()..color = const Color(0xFFF0997B).withValues(alpha: 0.25),
    );

    // Belly shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(100 * s, 178 * s), width: 124 * s, height: 28 * s),
      Paint()..color = SpecMochi.shadow,
    );

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(100 * s, 135 * s), width: 100 * s, height: 84 * s),
      Paint()..color = SpecMochi.furLight,
    );

    // Head
    canvas.drawCircle(Offset(100 * s, 80 * s), 42 * s, Paint()..color = SpecMochi.furLight);

    // Left ear
    final leftEar = Path()
      ..moveTo(66 * s, 56 * s)..lineTo(60 * s, 26 * s)..lineTo(88 * s, 48 * s)..close();
    canvas.drawPath(leftEar, Paint()..color = SpecMochi.furLight);
    // Left inner ear
    final leftInner = Path()
      ..moveTo(70 * s, 52 * s)..lineTo(68 * s, 36 * s)..lineTo(82 * s, 48 * s)..close();
    canvas.drawPath(leftInner, Paint()..color = SpecMochi.innerEar);

    // Right ear
    final rightEar = Path()
      ..moveTo(134 * s, 56 * s)..lineTo(140 * s, 26 * s)..lineTo(112 * s, 48 * s)..close();
    canvas.drawPath(rightEar, Paint()..color = SpecMochi.furLight);
    // Right inner ear
    final rightInner = Path()
      ..moveTo(130 * s, 52 * s)..lineTo(132 * s, 36 * s)..lineTo(118 * s, 48 * s)..close();
    canvas.drawPath(rightInner, Paint()..color = SpecMochi.innerEar);

    // Eyes (squinting — brand trademark, DO NOT change to open eyes)
    final eyePaint = Paint()
      ..color = SpecMochi.eyes..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * s..strokeCap = StrokeCap.round;
    final leftEye = Path()
      ..moveTo(78 * s, 82 * s)..quadraticBezierTo(84 * s, 76 * s, 90 * s, 82 * s);
    canvas.drawPath(leftEye, eyePaint);
    final rightEye = Path()
      ..moveTo(110 * s, 82 * s)..quadraticBezierTo(116 * s, 76 * s, 122 * s, 82 * s);
    canvas.drawPath(rightEye, eyePaint);

    // Blush
    canvas.drawOval(
      Rect.fromCenter(center: Offset(78 * s, 92 * s), width: 12 * s, height: 6 * s),
      Paint()..color = SpecMochi.blush,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(122 * s, 92 * s), width: 12 * s, height: 6 * s),
      Paint()..color = SpecMochi.blush,
    );

    // Nose
    final nose = Path()
      ..moveTo(96 * s, 94 * s)..lineTo(104 * s, 94 * s)..lineTo(100 * s, 99 * s)..close();
    canvas.drawPath(nose, Paint()..color = SpecMochi.nose);

    // Mouth
    final mouthPaint = Paint()
      ..color = SpecMochi.eyes..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s..strokeCap = StrokeCap.round;
    final leftMouth = Path()
      ..moveTo(100 * s, 99 * s)..quadraticBezierTo(95 * s, 104 * s, 91 * s, 101 * s);
    canvas.drawPath(leftMouth, mouthPaint);
    final rightMouth = Path()
      ..moveTo(100 * s, 99 * s)..quadraticBezierTo(105 * s, 104 * s, 109 * s, 101 * s);
    canvas.drawPath(rightMouth, mouthPaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = SpecMochi.whiskers..style = PaintingStyle.stroke
      ..strokeWidth = 1 * s..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(70 * s, 93 * s), Offset(54 * s, 90 * s), whiskerPaint);
    canvas.drawLine(Offset(70 * s, 99 * s), Offset(54 * s, 100 * s), whiskerPaint);
    canvas.drawLine(Offset(130 * s, 93 * s), Offset(146 * s, 90 * s), whiskerPaint);
    canvas.drawLine(Offset(130 * s, 99 * s), Offset(146 * s, 100 * s), whiskerPaint);

    // Tail
    final tailPaint = Paint()
      ..color = SpecMochi.furLight..style = PaintingStyle.stroke
      ..strokeWidth = 16 * s..strokeCap = StrokeCap.round;
    final tail = Path()
      ..moveTo(148 * s, 145 * s)..quadraticBezierTo(178 * s, 130 * s, 168 * s, 95 * s);
    canvas.drawPath(tail, tailPaint);
    // Tail stripe
    final tailStripe = Paint()
      ..color = SpecMochi.furDark.withValues(alpha: 0.5)..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s..strokeCap = StrokeCap.round;
    canvas.drawPath(tail, tailStripe);

    // Paws
    canvas.drawOval(
      Rect.fromCenter(center: Offset(82 * s, 172 * s), width: 22 * s, height: 14 * s),
      Paint()..color = SpecMochi.furDark,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(118 * s, 172 * s), width: 22 * s, height: 14 * s),
      Paint()..color = SpecMochi.furDark,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// SPEC Section 4.2 — Mochi Avatar (60×60 viewBox)
/// Small avatar for Home check-in card, Stats signature, Profile default avatar.
class MochiAvatar extends StatelessWidget {
  final double size;
  const MochiAvatar({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _MochiAvatarPainter());
  }
}

class _MochiAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 60;

    // Face
    canvas.drawCircle(Offset(30 * s, 34 * s), 22 * s, Paint()..color = SpecMochi.furLight);

    // Ears
    final leftEar = Path()
      ..moveTo(13 * s, 22 * s)..lineTo(10 * s, 6 * s)..lineTo(23 * s, 18 * s)..close();
    canvas.drawPath(leftEar, Paint()..color = SpecMochi.furLight);
    final rightEar = Path()
      ..moveTo(47 * s, 22 * s)..lineTo(50 * s, 6 * s)..lineTo(37 * s, 18 * s)..close();
    canvas.drawPath(rightEar, Paint()..color = SpecMochi.furLight);

    // Inner ears
    final leftInner = Path()
      ..moveTo(15 * s, 18 * s)..lineTo(14 * s, 10 * s)..lineTo(21 * s, 17 * s)..close();
    canvas.drawPath(leftInner, Paint()..color = SpecMochi.innerEar);
    final rightInner = Path()
      ..moveTo(45 * s, 18 * s)..lineTo(46 * s, 10 * s)..lineTo(39 * s, 17 * s)..close();
    canvas.drawPath(rightInner, Paint()..color = SpecMochi.innerEar);

    // Eyes
    final eyePaint = Paint()
      ..color = SpecMochi.eyes..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s..strokeCap = StrokeCap.round;
    final leftEye = Path()
      ..moveTo(20 * s, 33 * s)..quadraticBezierTo(24 * s, 29 * s, 28 * s, 33 * s);
    canvas.drawPath(leftEye, eyePaint);
    final rightEye = Path()
      ..moveTo(32 * s, 33 * s)..quadraticBezierTo(36 * s, 29 * s, 40 * s, 33 * s);
    canvas.drawPath(rightEye, eyePaint);

    // Blush
    canvas.drawOval(
      Rect.fromCenter(center: Offset(20 * s, 40 * s), width: 8 * s, height: 4 * s),
      Paint()..color = SpecMochi.blush,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(40 * s, 40 * s), width: 8 * s, height: 4 * s),
      Paint()..color = SpecMochi.blush,
    );

    // Nose
    final nose = Path()
      ..moveTo(28 * s, 41 * s)..lineTo(32 * s, 41 * s)..lineTo(30 * s, 44 * s)..close();
    canvas.drawPath(nose, Paint()..color = SpecMochi.nose);

    // Mouth
    final mouthPaint = Paint()
      ..color = SpecMochi.eyes..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()..moveTo(30 * s, 44 * s)..quadraticBezierTo(27 * s, 47 * s, 25 * s, 45 * s),
      mouthPaint,
    );
    canvas.drawPath(
      Path()..moveTo(30 * s, 44 * s)..quadraticBezierTo(33 * s, 47 * s, 35 * s, 45 * s),
      mouthPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// SPEC Section 4.3 — Paw Print
/// Used as watermark/decoration. Supports color and opacity props.
class PawPrint extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const PawPrint({
    super.key,
    this.size = 40,
    this.color = const Color(0xFFFFFFFF),
    this.opacity = 0.18,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(size: Size(size, size), painter: _PawPrintPainter(color)),
    );
  }
}

class _PawPrintPainter extends CustomPainter {
  final Color color;
  _PawPrintPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final paint = Paint()..color = color;

    // Main pad
    canvas.drawOval(
      Rect.fromCenter(center: Offset(20 * s, 26 * s), width: 18 * s, height: 14 * s),
      paint,
    );
    // Toe pads
    canvas.drawOval(
      Rect.fromCenter(center: Offset(9 * s, 16 * s), width: 7 * s, height: 9 * s),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(17 * s, 11 * s), width: 7 * s, height: 9 * s),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(25 * s, 11 * s), width: 7 * s, height: 9 * s),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(32 * s, 16 * s), width: 7 * s, height: 9 * s),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PawPrintPainter old) => old.color != color;
}
