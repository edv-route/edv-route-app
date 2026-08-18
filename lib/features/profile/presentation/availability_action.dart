import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/entities/driver.dart';

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
