import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../core/push/push_service.dart';
import '../../routing/app_routes.dart';

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

  // BEFORE clearing the session: revoking the phone's push token needs it. If
  // this is skipped, the next person to sign in on this handset receives the
  // previous driver's amounts and rejection reasons. It is privacy, not tidiness.
  await PushService.instance.disable();
  await Dependencies.instance.authRepository.logout();
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.selection,
      (route) => false,
    );
  }
}
