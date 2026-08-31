import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';

/// The decorative city-map illustration behind the passenger home (approved
/// mock-up, 2026-08-31). It is DECLARED as an illustration on screen; when the
/// trips module exists this space becomes the real map with the nearest
/// driver, without redesigning the screen.
///
/// Painted, not an asset: it scales to any phone for free and costs no bytes.
/// All positions are fractions of the canvas so the composition holds.
class CityMapPainter extends CustomPainter {
  const CityMapPainter();

  static const _background = Color(0xFFEDF0E8);
  static const _blockA = Color(0xFFE3E8DC);
  static const _blockB = Color(0xFFE6EBDF);
  static const _road = Colors.white;
  static const _goldDash = Color(0xFFF3E6BD);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(Offset.zero & size, Paint()..color = _background);

    // City blocks between the roads.
    void block(double x, double y, double bw, double bh, Color color) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x * w, y * h, bw * w, bh * h), const Radius.circular(10)),
        Paint()..color = color,
      );
    }

    block(-0.05, 0.06, 0.36, 0.22, _blockA);
    block(0.41, 0.02, 0.32, 0.26, _blockB);
    block(0.80, 0.08, 0.30, 0.20, _blockA);
    block(-0.07, 0.39, 0.41, 0.24, _blockB);
    block(0.63, 0.37, 0.44, 0.26, _blockA);
    block(-0.02, 0.74, 0.44, 0.30, _blockA);
    block(0.56, 0.72, 0.48, 0.32, _blockB);

    // Roads: soft white strokes, slightly askew so it reads as a city, not a grid.
    void road(Offset a, Offset b, double width, {Color color = _road}) {
      canvas.drawLine(
        Offset(a.dx * w, a.dy * h),
        Offset(b.dx * w, b.dy * h),
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    road(const Offset(0, 0.33), const Offset(1, 0.30), 18);
    road(const Offset(0, 0.68), const Offset(1, 0.65), 16);
    road(const Offset(0.36, 0), const Offset(0.42, 1), 20);
    road(const Offset(0.78, 0), const Offset(0.73, 1), 12);
    road(const Offset(0, 0.51), const Offset(1, 0.49), 8);
    road(const Offset(0.15, 0), const Offset(0.17, 1), 7);

    // Gold dashes down the main avenue — the brand sneaking into the scenery.
    final dashPaint = Paint()
      ..color = _goldDash
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    const dashCount = 9;
    for (var i = 0; i < dashCount; i++) {
      final t1 = i / dashCount;
      final t2 = t1 + 0.055;
      canvas.drawLine(
        Offset((0.36 + (0.42 - 0.36) * t1) * w, t1 * h),
        Offset((0.36 + (0.42 - 0.36) * t2) * w, t2 * h),
        dashPaint,
      );
    }

    // Tiny cars on the roads, purely decorative.
    void car(double x, double y, double angleDeg, Color color) {
      canvas.save();
      canvas.translate(x * w, y * h);
      canvas.rotate(angleDeg * 3.1415926 / 180);
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-13, -7, 26, 14), const Radius.circular(5)),
        Paint()..color = color,
      );
      canvas.restore();
    }

    car(0.50, 0.40, 3, AppColors.primary);
    car(0.24, 0.675, -2, const Color(0xFF6B7280));
    car(0.745, 0.24, 85, const Color(0xFFB3891F));

    // The «you are here» pin.
    final pinCenter = Offset(0.5 * w, 0.55 * h);
    canvas.drawCircle(pinCenter, 26, Paint()..color = AppColors.primary.withValues(alpha: 0.12));
    final drop = Path()
      ..moveTo(pinCenter.dx, pinCenter.dy - 28)
      ..cubicTo(pinCenter.dx - 12, pinCenter.dy - 28, pinCenter.dx - 20, pinCenter.dy - 19,
          pinCenter.dx - 20, pinCenter.dy - 8)
      ..cubicTo(pinCenter.dx - 20, pinCenter.dy + 6, pinCenter.dx, pinCenter.dy + 22,
          pinCenter.dx, pinCenter.dy + 22)
      ..cubicTo(pinCenter.dx, pinCenter.dy + 22, pinCenter.dx + 20, pinCenter.dy + 6,
          pinCenter.dx + 20, pinCenter.dy - 8)
      ..cubicTo(pinCenter.dx + 20, pinCenter.dy - 19, pinCenter.dx + 12, pinCenter.dy - 28,
          pinCenter.dx, pinCenter.dy - 28)
      ..close();
    canvas.drawPath(drop, Paint()..color = AppColors.primary);
    canvas.drawCircle(Offset(pinCenter.dx, pinCenter.dy - 9), 7, Paint()..color = AppColors.gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The little brand-red taxi that decorates the golden search card (lifted
/// from the approved mock-up's SVG, 120×60 design space scaled to the size).
class TaxiCarPainter extends CustomPainter {
  const TaxiCarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 120;
    final sy = size.height / 60;
    canvas.scale(sx, sy);

    final body = Path()
      ..moveTo(14, 42)
      ..cubicTo(14, 30, 26, 24, 42, 24)
      ..lineTo(52, 14)
      ..cubicTo(54, 11, 58, 10, 64, 10)
      ..lineTo(84, 10)
      ..cubicTo(92, 10, 98, 16, 102, 24)
      ..cubicTo(110, 26, 114, 32, 114, 38)
      ..lineTo(114, 42)
      ..close();
    canvas.drawPath(body, Paint()..color = AppColors.primary);

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(58, 14, 18, 10), const Radius.circular(3)),
      Paint()..color = const Color(0xFFFDF8E3),
    );

    for (final cx in const [36.0, 92.0]) {
      canvas.drawCircle(Offset(cx, 44), 9, Paint()..color = AppColors.primary950);
      canvas.drawCircle(Offset(cx, 44), 4, Paint()..color = AppColors.gold);
    }

    final speed = Paint()
      ..color = const Color(0xFFD9C268)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(4, 50), const Offset(26, 50), speed);
    canvas.drawLine(const Offset(0, 56), const Offset(18, 56), speed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
