import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../routing/app_routes.dart';
import '../../../home/presentation/screens/driver_root_screen.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/driver.dart';
import '../../../client/home/presentation/screens/client_shell.dart';
import '../../../enrollment/presentation/screens/checklist_hub_screen.dart';

/// App entry point: resumes a stored session on launch — the driver's first,
/// then the client's (the UI never lets both exist at once: reaching the other
/// mode's login requires logging out). A driver routes by status through
/// [DriverRootScreen]; a client goes straight to his shell; no session (or an
/// expired one) falls back to the user-type selection. A transport error keeps
/// the token and still falls back to selection so the user can retry.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    Driver? driver;
    try {
      driver = await Dependencies.instance.authRepository.currentDriver();
    } catch (_) {
      driver = null; // couldn't reach the server → go to selection (token kept)
    }
    if (!mounted) return;
    final d = driver;
    final navigator = Navigator.of(context);
    if (d != null) {
      if (d.status == DriverStatus.applicant) {
        navigator.pushReplacement(MaterialPageRoute(builder: (_) => const ChecklistHubScreen()));
      } else {
        navigator.pushReplacement(MaterialPageRoute(builder: (_) => DriverRootScreen(driver: d)));
      }
      return;
    }

    Client? client;
    try {
      client = await Dependencies.instance.clientAuthRepository.currentClient();
    } catch (_) {
      client = null; // same rule as the driver: token kept, selection shown
    }
    if (!mounted) return;
    final c = client;
    if (c != null) {
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => ClientShell(client: c)));
    } else {
      navigator.pushReplacementNamed(AppRoutes.selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
