import 'package:flutter/material.dart';

import '../../../auth/domain/entities/driver.dart';
import '../../../auth/presentation/screens/checklist_screen.dart';
import 'driver_shell.dart';
import 'driver_status_screen.dart';

/// Entry point after login/bootstrap: an `applicant` still completing his solicitud
/// lands on the checklist; an approved driver on the app shell; any other status
/// (in review / suspended / rejected) sees the status screen instead.
class DriverRootScreen extends StatelessWidget {
  final Driver driver;

  const DriverRootScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    if (driver.status == DriverStatus.applicant) return const ChecklistScreen();
    final isActive = driver.status == DriverStatus.approved ||
        driver.status == DriverStatus.unknown;
    return isActive ? DriverShell(driver: driver) : DriverStatusScreen(driver: driver);
  }
}
