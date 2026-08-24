import 'package:flutter/material.dart';

import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';

/// The end of the recovery. Its only job is to say the change stuck and put the
/// driver back at the login — the flow he came here to finish.
///
/// It does NOT promise that other phones were signed out: driver sessions are
/// validated by signature alone and stay alive up to 8h, so saying otherwise
/// would be the app telling him something that is not true.
class PasswordResetDoneScreen extends StatelessWidget {
  const PasswordResetDoneScreen({super.key});

  /// The "Aprobado" green the checklist already uses.
  static const _okBg = Color(0xFFDCFCE7);
  static const _okFg = Color(0xFF166534);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: 'Listo',
            subtitle: 'Ya puedes volver a entrar',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(color: _okBg, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 44, color: _okFg),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Tu clave fue actualizada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ya puedes entrar con tu cédula y tu clave nueva. Te enviamos un correo confirmando el cambio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Ir a iniciar sesión',
                      // Back to the login that started this, not a new one on
                      // top of it: the recovery screens must not stay behind.
                      onPressed: () => Navigator.of(context)
                          .popUntil(ModalRoute.withName(AppRoutes.driverLogin)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
