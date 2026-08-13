import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// Rounded header painted with the official EDV red-to-black brand gradient,
/// plus a subtle decorative layer (a gold glow and faint forward-slanting speed
/// streaks that echo the EDV logo). Forces light status-bar icons.
class GradientHeader extends StatelessWidget {
  final Widget child;

  /// Fixed content height (below the status bar). Null hugs the content.
  final double? height;

  /// Uniform header height shared by every screen so they all line up.
  static const double kStandardHeight = 140;

  const GradientHeader({super.key, required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      // Full-bleed: force the header to fill the available width. Without this the
      // DecoratedBox shrink-wraps to its content (logo/title) and the parent Column
      // centers it, leaving side margins that grow wider on larger screens.
      child: SizedBox(
        width: double.infinity,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
            ),
            child: CustomPaint(
              painter: _HeaderDecorPainter(),
              child: SafeArea(
                bottom: false,
                child: SizedBox(height: height, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Soft gold glow in the top-right corner for depth.
    final glowCenter = Offset(size.width * 0.92, size.height * 0.12);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.20),
          AppColors.gold.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: 150));
    canvas.drawCircle(glowCenter, 150, glow);

    // Faint forward-slanting speed streaks (echo the EDV logo's motion).
    final streaks = <(double, double, double)>[
      (size.height * 0.34, 44.0, 0.06),
      (size.height * 0.60, 30.0, 0.05),
      (size.height * 0.82, 20.0, 0.04),
    ];
    for (final (dy, width, opacity) in streaks) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(-40, dy + 42),
        Offset(size.width * 0.72, dy - 34),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
