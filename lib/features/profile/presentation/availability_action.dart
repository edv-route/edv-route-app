import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/driver.dart';
import '../../../theme/app_colors.dart';

/// Puts the driver on or off duty and reports the result upwards.
///
/// Shared by Inicio and Perfil because the switch lives in the header both
/// screens use. The backend refuses to activate a driver whose status does not
/// let him operate (penalized/paused) — when that happens the switch must snap
/// back and say why, never look as if it worked.
Future<void> applyAvailability({
  required BuildContext context,
  required Driver driver,
  required bool available,
  required ValueChanged<Driver> onDriverChanged,
}) async {
  // Going OFF duty is explained before it happens. Going ON duty is not: nobody
  // needs a dialog to be told that working means working.
  if (!available) {
    final confirmed = await _confirmGoingOffDuty(context);
    if (confirmed != true) {
      // The switch already moved under his finger: put it back.
      onDriverChanged(driver.copyWith(isAvailable: driver.isAvailable));
      return;
    }
    if (!context.mounted) return;
  }

  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await Dependencies.instance.accountRepository.setAvailability(available);
    onDriverChanged(driver.copyWith(isAvailable: result));
  } on ApiException catch (e) {
    onDriverChanged(driver.copyWith(isAvailable: driver.isAvailable));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    onDriverChanged(driver.copyWith(isAvailable: driver.isAvailable));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('No se pudo cambiar tu estado. Intenta de nuevo.')));
  }
}

/// Spells out what going off duty actually costs him.
///
/// The one that matters is the tariff: it keeps running whether he works or
/// not — the weekly charge does not look at `is_available` — and a driver who
/// switches off for a week thinking it pauses his debt comes back owing money
/// he did not expect. Better a dialog now than that conversation later.
Future<bool?> _confirmGoingOffDuty(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Ponerte inactivo?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Mientras estés inactivo:',
            style: TextStyle(fontSize: 14, color: AppColors.ink),
          ),
          SizedBox(height: 12),
          _OffDutyPoint(
            icon: Icons.block,
            text: 'No vas a recibir viajes. Los que estén disponibles se le asignan a otro afiliado.',
          ),
          _OffDutyPoint(
            icon: Icons.location_off,
            text: 'Dejas de compartir tu ubicación con la asociación.',
          ),
          _OffDutyPoint(
            icon: Icons.payments_outlined,
            text: 'Tu tarifa sigue corriendo. Ponerte inactivo no detiene lo que se cobra cada semana.',
            emphasis: true,
          ),
          SizedBox(height: 4),
          Text(
            'Puedes volver a activarte cuando quieras.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Seguir activo'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Ponerme inactivo'),
        ),
      ],
    ),
  );
}

class _OffDutyPoint extends StatelessWidget {
  const _OffDutyPoint({required this.icon, required this.text, this.emphasis = false});

  final IconData icon;
  final String text;

  /// The money one. It is the consequence a driver does not see coming.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: emphasis ? AppColors.primary : AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: emphasis ? AppColors.ink : AppColors.muted,
                fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
