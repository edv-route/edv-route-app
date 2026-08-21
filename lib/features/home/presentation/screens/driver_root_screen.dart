import 'package:flutter/material.dart';

import '../../../../core/push/push_service.dart';
import '../../../../domain/entities/driver.dart';
import '../../../enrollment/presentation/screens/alta_payment_screen.dart';
import '../../../enrollment/presentation/screens/checklist_hub_screen.dart';
import './driver_shell.dart';
import './driver_status_screen.dart';

/// Entry point after login/bootstrap, by status: an `applicant` still completing
/// his solicitud lands on the checklist; an `approved` driver goes through the
/// deferred alta payment gate (which pays if he owes, or passes to the app shell
/// when settled); any other status (in review / suspended / rejected) sees the
/// status screen.
class DriverRootScreen extends StatefulWidget {
  final Driver driver;

  const DriverRootScreen({super.key, required this.driver});

  @override
  State<DriverRootScreen> createState() => _DriverRootScreenState();
}

class _DriverRootScreenState extends State<DriverRootScreen> {
  @override
  void initState() {
    super.initState();
    // The push token is registered HERE and not in the shell because an
    // `applicant` never reaches the shell — and he is precisely the one waiting
    // for the verdict of his solicitud. This is the one point every
    // authenticated state passes through, whatever screen it lands on.
    //
    // Not awaited: it asks for a permission and talks to two networks, and the
    // driver must not stare at a blank screen while that happens.
    PushService.instance.syncToken();
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    switch (driver.status) {
      case DriverStatus.applicant:
        return const ChecklistHubScreen();
      // An approved driver whose tariff ALREADY STARTED is an affiliate who has
      // been working: the app opens on the app, not on a payment gate. Only the
      // one still waiting for the office to activate him passes through the alta
      // screen. Before this, an operating driver who owed his week landed on
      // "Paga tu alta — registra el pago para activarte", which is false for
      // someone who has been driving for weeks, and a payment left him locked
      // out of his own account (2026-08-21).
      case DriverStatus.approved:
        return driver.tariffStarted
            ? DriverShell(driver: driver)
            : AltaPaymentScreen(driver: driver);
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
      // A `pending` affiliate may OWE money: a panel registration without payment
      // leaves him owing the alta, and so does a reverted receipt. Routing him
      // straight to "solicitud en revisión" trapped him there with no way to pay
      // (2026-08-19). The payment screen asks for his debt and, when there is
      // none, shows that same review notice itself.
      case DriverStatus.pending:
        return AltaPaymentScreen(driver: driver);
      case DriverStatus.rejected:
      case DriverStatus.suspended:
        return DriverStatusScreen(driver: driver);
    }
  }
}
