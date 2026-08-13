import 'package:flutter/material.dart';

import '../../../auth/domain/entities/driver.dart';
import 'driver_shell.dart';
import 'driver_status_screen.dart';

/// Entry point after login: an approved driver lands on the app shell; any other
/// status (in review / suspended / rejected) sees the status screen instead.
class DriverRootScreen extends StatelessWidget {
  final Driver driver;

  const DriverRootScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final isActive = driver.status == DriverStatus.approved ||
        driver.status == DriverStatus.unknown;
    return isActive ? DriverShell(driver: driver) : DriverStatusScreen(driver: driver);
  }
}
