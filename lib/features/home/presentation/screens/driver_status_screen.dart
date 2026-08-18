import 'package:flutter/material.dart';

import '../../../../shared/widgets/auth_header.dart';
import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/driver.dart';
import '../../../../shared/actions/logout_action.dart';

/// Shown after login when the driver is NOT approved: in review, suspended or
/// rejected. Simple full-screen message + logout.
class DriverStatusScreen extends StatelessWidget {
  final Driver driver;

  const DriverStatusScreen({super.key, required this.driver});

  ({String title, String body, IconData icon}) get _view => switch (driver.status) {
        DriverStatus.pending => (
            title: 'Solicitud en revisión',
            body: 'Estamos revisando tu solicitud. Te avisaremos cuando esté lista.',
            icon: Icons.hourglass_top_outlined,
          ),
        DriverStatus.suspended => (
            title: 'Cuenta suspendida',
            body: 'Tu cuenta está suspendida. Contacta al administrador.',
            icon: Icons.lock_outline,
          ),
        DriverStatus.rejected => (
            title: 'Solicitud rechazada',
            body: 'Tu solicitud fue rechazada. Contacta al administrador.',
            icon: Icons.block_outlined,
          ),
        _ => (
            title: 'Sesión iniciada',
            body: 'Bienvenido de nuevo.',
            icon: Icons.person_outline,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final view = _view;
    final firstName = driver.fullName.split(' ').first;

    return Scaffold(
      body: Column(
        children: [
          AuthHeader(title: 'Hola, $firstName'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Icon(view.icon, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    view.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    view.body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => performLogout(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Cerrar sesión'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
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
