import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../core/location/location_service.dart';
import '../../core/push/push_service.dart';
import '../../routing/app_routes.dart';

/// Confirms, clears the stored session, and returns to the mode-selection
/// screen. Shared by the profile and status screens so logout is defined once.
Future<void> performLogout(BuildContext context) async {
  if (!await _confirmLogout(context)) return;
  if (!context.mounted) return;

  // BEFORE clearing the session: revoking the phone's push token needs it. If
  // this is skipped, the next person to sign in on this handset receives the
  // previous driver's amounts and rejection reasons. It is privacy, not tidiness.
  await PushService.instance.disable();
  // Same reasoning for tracking: stop reporting AND forget the queued points.
  // A foreground service left running after logout would keep reporting under a
  // session that no longer exists, and the queue would hand the next driver on
  // this phone the previous one's positions.
  await LocationService().stopAndClear();
  await Dependencies.instance.authRepository.logout();
  if (context.mounted) _backToSelection(context);
}

/// The passenger's logout: same confirmation and same destination, but WITHOUT
/// the driver-only teardown — a client session registers no push token and
/// runs no location service, so there is nothing to revoke or stop.
Future<void> performClientLogout(BuildContext context) async {
  if (!await _confirmLogout(context)) return;
  await Dependencies.instance.clientAuthRepository.logout();
  if (context.mounted) _backToSelection(context);
}

Future<bool> _confirmLogout(BuildContext context) async {
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
  return confirmed == true;
}

void _backToSelection(BuildContext context) {
  Navigator.of(context).pushNamedAndRemoveUntil(
    AppRoutes.selection,
    (route) => false,
  );
}
