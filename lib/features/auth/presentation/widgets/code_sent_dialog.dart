import 'package:flutter/material.dart';

import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';

/// Confirms the code left, and to WHICH address — the user just typed it, so
/// showing it in full lets them catch their own typo before waiting on mail
/// that went to the wrong place. Shared by the driver and the client recovery
/// flows: the moment "go read your mail" reads the same on both.
class CodeSentDialog extends StatelessWidget {
  const CodeSentDialog({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_outlined, size: 30, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            const Text(
              'Validación exitosa',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enviamos un código de 6 dígitos a',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
            ),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revisa tu bandeja de entrada. El código vence en 10 minutos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Entendido',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
