import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../routing/app_routes.dart';

/// Confirms, clears the stored session, and returns to the mode-selection
/// screen. Shared by the profile and status screens so logout is defined once.
Future<void> performLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Seguro que quieres salir de tu cuenta?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  await Dependencies.instance.authRepository.logout();
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.selection,
      (route) => false,
    );
  }
}
