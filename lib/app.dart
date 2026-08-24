import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import './features/auth/presentation/screens/driver_login_screen.dart';
import 'features/auth/presentation/screens/password_reset_identity_screen.dart';
import './features/auth/presentation/screens/driver_register_screen.dart';
import './features/enrollment/presentation/screens/membership_info_screen.dart';
import './features/auth/presentation/screens/splash_screen.dart';
import './features/auth/presentation/screens/user_type_selection_screen.dart';
import './routing/app_routes.dart';
import './theme/app_theme.dart';

/// Root widget: wires the brand theme and the auth route graph.
class EdvRouteApp extends StatelessWidget {
  const EdvRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EDV Route',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Spanish across all Material widgets (date picker months/days/buttons, etc.).
      locale: const Locale('es'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      initialRoute: AppRoutes.boot,
      routes: {
        AppRoutes.boot: (_) => const SplashScreen(),
        AppRoutes.selection: (_) => const UserTypeSelectionScreen(),
        AppRoutes.driverLogin: (_) => const DriverLoginScreen(),
        AppRoutes.passwordReset: (_) => const PasswordResetIdentityScreen(),
        AppRoutes.registerIntro: (_) => const MembershipInfoScreen(),
        AppRoutes.driverRegister: (_) => const DriverRegisterScreen(),
      },
    );
  }
}
