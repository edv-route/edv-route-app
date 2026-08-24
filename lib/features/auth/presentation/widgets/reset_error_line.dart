import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// The failure message of a recovery step, shown NEXT TO the button that caused
/// it — never in a banner at the top of the screen. These forms are taller than
/// the viewport and a banner up there is read by nobody; that exact diagnosis is
/// why the panel moved its own errors down (2026-07-16).
///
/// The text always comes from the server: it knows things the app does not
/// ("Te quedan 2 intentos", "Espera 47 segundos").
class ResetErrorLine extends StatelessWidget {
  const ResetErrorLine({super.key, required this.message, this.center = false});

  final String message;

  /// Centred under the code boxes, left-aligned under a form field.
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.error_outline, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            message,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
