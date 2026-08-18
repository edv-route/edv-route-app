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
      // A driver in arrears — even a PENALIZED one — enters the app (decision
      // 2026-08-18): he must be able to see what he owes and pay it. What he
      // loses is the WORK: no trips, no benefits (and more restrictions to come).
      // That gate belongs to each feature, keyed on `DriverStatus.canOperate`,
      // never to the entrance: locking him out of the app would also lock him
      // out of the only screen where he can settle his debt.
      case DriverStatus.overdue:
      case DriverStatus.penalized:
      case DriverStatus.paused:
      case DriverStatus.scheduled:
      case DriverStatus.unknown:
        return DriverShell(driver: driver);
      case DriverStatus.pending:
      case DriverStatus.rejected:
      case DriverStatus.suspended:
        return DriverStatusScreen(driver: driver);
    }
  }
}
