import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Darkens everything except an oval where the face goes, and outlines it.
/// The person centres his face himself: no detection, just a clear target.
class OvalGuidePainter extends CustomPainter {
  const OvalGuidePainter();

  /// The oval, shared with the layout so the hint can sit right under it.
  static Rect ovalFor(Size size) {
    final width = size.width * 0.64;
    final height = width * 1.32;
    return Rect.fromLTWH((size.width - width) / 2, size.height * 0.2, width, height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final oval = ovalFor(size);
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(oval);
    canvas.drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.62));
    canvas.drawOval(
      oval,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant OvalGuidePainter oldDelegate) => false;
}

/// Darkens everything except a card-shaped window (ID-1, 85.6 × 54 mm) with
/// gold corner brackets — the frame the cédula should fill.
class CardGuidePainter extends CustomPainter {
  const CardGuidePainter();

  static const double _ratio = 85.6 / 54;

  static Rect frameFor(Size size) {
    final width = size.width - 60;
    final height = width / _ratio;
    return Rect.fromLTWH(30, size.height * 0.31, width, height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final frame = frameFor(size);
    final rrect = RRect.fromRectAndRadius(frame, const Radius.circular(14));
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rrect);
    canvas.drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.62));

    final bracket = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const arm = 30.0;
    final corners = [
      (frame.topLeft, 1.0, 1.0),
      (frame.topRight, -1.0, 1.0),
      (frame.bottomLeft, 1.0, -1.0),
      (frame.bottomRight, -1.0, -1.0),
    ];
    for (final (point, dx, dy) in corners) {
      canvas.drawLine(point, point.translate(arm * dx, 0), bracket);
      canvas.drawLine(point, point.translate(0, arm * dy), bracket);
    }
  }

  @override
  bool shouldRepaint(covariant CardGuidePainter oldDelegate) => false;
}
