import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../routing/app_routes.dart';
import '../../../home/presentation/screens/driver_root_screen.dart';
import '../../domain/entities/driver.dart';
import 'checklist_hub_screen.dart';

/// App entry point: resumes a stored session on launch. Reads the token + GET /me
/// and routes accordingly — an `applicant` to his checklist, any other driver
/// through [DriverRootScreen] — or falls back to the user-type selection when
/// there is no session (or it expired). A transport error keeps the token and
/// still falls back to selection so the user can retry from login.
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
    if (d == null) {
      navigator.pushReplacementNamed(AppRoutes.selection);
    } else if (d.status == DriverStatus.applicant) {
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => const ChecklistHubScreen()));
    } else {
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => DriverRootScreen(driver: d)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
