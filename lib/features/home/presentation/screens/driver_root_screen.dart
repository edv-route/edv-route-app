import 'package:flutter/material.dart';

import '../../../auth/domain/entities/driver.dart';
import '../../../auth/presentation/screens/alta_payment_screen.dart';
import '../../../auth/presentation/screens/checklist_hub_screen.dart';
import 'driver_shell.dart';
import 'driver_status_screen.dart';

/// Entry point after login/bootstrap, by status: an `applicant` still completing
/// his solicitud lands on the checklist; an `approved` driver goes through the
/// deferred alta payment gate (which pays if he owes, or passes to the app shell
/// when settled); any other status (in review / suspended / rejected) sees the
/// status screen.
class DriverRootScreen extends StatelessWidget {
  final Driver driver;

  const DriverRootScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    switch (driver.status) {
      case DriverStatus.applicant:
        return const ChecklistHubScreen();
      case DriverStatus.approved:
        return AltaPaymentScreen(driver: driver);
      case DriverStatus.unknown:
        return DriverShell(driver: driver);
      case DriverStatus.pending:
      case DriverStatus.rejected:
      case DriverStatus.suspended:
        return DriverStatusScreen(driver: driver);
    }
  }
}
