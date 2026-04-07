import 'package:flutter/material.dart';

/// SPEC Section 4.4 — Tab bar icons (filled style, warm beige + brown stroke)
///
/// Unified rules:
/// - viewBox: 0 0 28 28
/// - Unselected fill: #F5EFE6 (deep: #ECE0CC), stroke: #C9B8A0, 1.3px
/// - Selected fill: #F5DEB3 (deep: #E8B89C), stroke: #B8845C, 1.5px
/// - All joins: round

// Icon color sets
class _IconColors {
  final Color fill;
  final Color fillDeep;
  final Color stroke;
  final double strokeWidth;

  const _IconColors({
    required this.fill,
    required this.fillDeep,
    required this.stroke,
    required this.strokeWidth,
  });

  static const unselected = _IconColors(
    fill: Color(0xFFF5EFE6),
    fillDeep: Color(0xFFECE0CC),
    stroke: Color(0xFFC9B8A0),
    strokeWidth: 1.3,
  );

  static const selected = _IconColors(
    fill: Color(0xFFF5DEB3),
    fillDeep: Color(0xFFE8B89C),
    stroke: Color(0xFFB8845C),
    strokeWidth: 1.5,
  );
}

/// 4.4.1 Home icon — house with door
class IconHome extends StatelessWidget {
  final bool isSelected;
  final double size;
  const IconHome({super.key, this.isSelected = false, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final c = isSelected ? _IconColors.selected : _IconColors.unselected;
    return CustomPaint(size: Size(size, size), painter: _HomePainter(c));
  }
}

class _HomePainter extends CustomPainter {
  final _IconColors c;
  _HomePainter(this.c);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 28;
    final fillPaint = Paint()..color = c.fill..style = PaintingStyle.fill;
    final fillDeepPaint = Paint()..color = c.fillDeep..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = c.stroke..style = PaintingStyle.stroke
      ..strokeWidth = c.strokeWidth * s
      ..strokeJoin = StrokeJoin.round;

    // House body
    final house = Path()
      ..moveTo(4 * s, 13 * s)..lineTo(14 * s, 4 * s)..lineTo(24 * s, 13 * s)
      ..lineTo(24 * s, 23 * s)..lineTo(4 * s, 23 * s)..close();
    canvas.drawPath(house, fillPaint);
    canvas.drawPath(house, strokePaint);

    // Door
    final door = RRect.fromLTRBR(11 * s, 16 * s, 17 * s, 23 * s, Radius.zero);
    canvas.drawRRect(door, fillDeepPaint);
    canvas.drawRRect(door, strokePaint..strokeWidth = 1.2 * s);
  }

  @override
  bool shouldRepaint(covariant _HomePainter old) => old.c != c;
}

/// 4.4.2 Books icon — three stacked bars
class IconBooks extends StatelessWidget {
  final bool isSelected;
  final double size;
  const IconBooks({super.key, this.isSelected = false, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final c = isSelected ? _IconColors.selected : _IconColors.unselected;
    return CustomPaint(size: Size(size, size), painter: _BooksPainter(c));
  }
}

class _BooksPainter extends CustomPainter {
  final _IconColors c;
  _BooksPainter(this.c);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 28;
    final stroke = Paint()
      ..color = c.stroke..style = PaintingStyle.stroke
      ..strokeWidth = c.strokeWidth * s;

    void drawBar(double x, double y, double w, double h, Color fill) {
      final rect = RRect.fromLTRBR(x * s, y * s, (x + w) * s, (y + h) * s, Radius.circular(1.2 * s));
      canvas.drawRRect(rect, Paint()..color = fill);
      canvas.drawRRect(rect, stroke);
    }

    drawBar(5, 6, 18, 4.5, c.fill);
    drawBar(4, 11.5, 20, 4.5, c.fillDeep);
    drawBar(6, 17, 16, 4.5, c.fill);
  }

  @override
  bool shouldRepaint(covariant _BooksPainter old) => old.c != c;
}

/// 4.4.3 Mochi icon — cat face
class IconMochi extends StatelessWidget {
  final bool isSelected;
  final double size;
  const IconMochi({super.key, this.isSelected = false, this.size = 26});

  @override
  Widget build(BuildContext context) {
    final c = isSelected ? _IconColors.selected : _IconColors.unselected;
    return CustomPaint(size: Size(size, size), painter: _MochiIconPainter(c));
  }
}

class _MochiIconPainter extends CustomPainter {
  final _IconColors c;
  _MochiIconPainter(this.c);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 28;
    final fill = Paint()..color = c.fill;
    final stroke = Paint()
      ..color = c.stroke..style = PaintingStyle.stroke
      ..strokeWidth = c.strokeWidth * s..strokeJoin = StrokeJoin.round;

    // Left ear
    final leftEar = Path()
      ..moveTo(8 * s, 9 * s)..lineTo(5.5 * s, 3.5 * s)..lineTo(11 * s, 7 * s)..close();
    canvas.drawPath(leftEar, fill);
    canvas.drawPath(leftEar, stroke);

    // Right ear
    final rightEar = Path()
      ..moveTo(20 * s, 9 * s)..lineTo(22.5 * s, 3.5 * s)..lineTo(17 * s, 7 * s)..close();
    canvas.drawPath(rightEar, fill);
    canvas.drawPath(rightEar, stroke);

    // Face circle
    canvas.drawCircle(Offset(14 * s, 15 * s), 8 * s, fill);
    canvas.drawCircle(Offset(14 * s, 15 * s), 8 * s, stroke);

    // Eyes (squinting — brand trademark)
    final eyeStroke = Paint()
      ..color = const Color(0xFF8A6A55)..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s..strokeCap = StrokeCap.round;

    final leftEye = Path()
      ..moveTo(11 * s, 14 * s)
      ..quadraticBezierTo(12 * s, 13 * s, 13 * s, 14 * s);
    canvas.drawPath(leftEye, eyeStroke);

    final rightEye = Path()
      ..moveTo(15 * s, 14 * s)
      ..quadraticBezierTo(16 * s, 13 * s, 17 * s, 14 * s);
    canvas.drawPath(rightEye, eyeStroke);

    // Nose
    final nose = Path()
      ..moveTo(13.3 * s, 16.5 * s)..lineTo(14.7 * s, 16.5 * s)..lineTo(14 * s, 17.4 * s)..close();
    canvas.drawPath(nose, Paint()..color = c.stroke);
  }

  @override
  bool shouldRepaint(covariant _MochiIconPainter old) => old.c != c;
}

/// 4.4.4 Stats icon — three bars chart
class IconStats extends StatelessWidget {
  final bool isSelected;
  final double size;
  const IconStats({super.key, this.isSelected = false, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final c = isSelected ? _IconColors.selected : _IconColors.unselected;
    return CustomPaint(size: Size(size, size), painter: _StatsPainter(c));
  }
}

class _StatsPainter extends CustomPainter {
  final _IconColors c;
  _StatsPainter(this.c);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 28;
    final stroke = Paint()
      ..color = c.stroke..style = PaintingStyle.stroke
      ..strokeWidth = c.strokeWidth * s;

    void drawBar(double x, double y, double w, double h, Color fill) {
      final rect = RRect.fromLTRBR(x * s, y * s, (x + w) * s, (y + h) * s, Radius.circular(1.2 * s));
      canvas.drawRRect(rect, Paint()..color = fill);
      canvas.drawRRect(rect, stroke);
    }

    drawBar(4.5, 15, 5, 8, c.fill);
    drawBar(11.5, 8, 5, 15, c.fillDeep);
    drawBar(18.5, 11.5, 5, 11.5, c.fill);
  }

  @override
  bool shouldRepaint(covariant _StatsPainter old) => old.c != c;
}

/// 4.4.5 Profile icon — person silhouette
class IconProfile extends StatelessWidget {
  final bool isSelected;
  final double size;
  const IconProfile({super.key, this.isSelected = false, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final c = isSelected ? _IconColors.selected : _IconColors.unselected;
    return CustomPaint(size: Size(size, size), painter: _ProfilePainter(c));
  }
}

class _ProfilePainter extends CustomPainter {
  final _IconColors c;
  _ProfilePainter(this.c);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 28;
    final fill = Paint()..color = c.fill;
    final stroke = Paint()
      ..color = c.stroke..style = PaintingStyle.stroke
      ..strokeWidth = c.strokeWidth * s..strokeJoin = StrokeJoin.round;

    // Head
    canvas.drawCircle(Offset(14 * s, 9 * s), 4.5 * s, fill);
    canvas.drawCircle(Offset(14 * s, 9 * s), 4.5 * s, stroke);

    // Body arc
    final body = Path()
      ..moveTo(4.5 * s, 24 * s)
      ..arcToPoint(Offset(23.5 * s, 24 * s), radius: Radius.circular(9.5 * s), clockwise: false)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter old) => old.c != c;
}

/// 5.1.6 Legacy tab icon — simple folder outline
/// Always #B4A89A, no selected/unselected distinction
class IconLegacy extends StatelessWidget {
  final double size;
  const IconLegacy({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _LegacyPainter());
  }
}

class _LegacyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 28;
    final stroke = Paint()
      ..color = const Color(0xFFB4A89A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(5 * s, 9 * s)..lineTo(11 * s, 9 * s)..lineTo(13 * s, 7 * s)
      ..lineTo(23 * s, 7 * s)..lineTo(23 * s, 21 * s)..lineTo(5 * s, 21 * s)..close();
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
