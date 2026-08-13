import 'package:flutter/material.dart';

import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';

/// Shown after a successful registration: the alta is created and pending admin
/// review. The driver logs in normally once approved.
class RegistrationDoneScreen extends StatelessWidget {
  const RegistrationDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: 'Solicitud enviada',
            subtitle: 'Tu registro quedó en revisión',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_outlined, size: 72, color: AppColors.gold),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Gracias por registrarte!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Un administrador revisará tu solicitud y tu pago. Cuando sea '
                    'aprobada podrás ingresar con tu cédula y tu clave.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'Ir al inicio de sesión',
                    onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.driverLogin,
                      (route) => route.isFirst,
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
