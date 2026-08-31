import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/features/auth/presentation/screens/user_type_selection_screen.dart';
import 'package:edv_route_mobile/theme/app_theme.dart';

void main() {
  testWidgets('Selection screen shows both modes live', (tester) async {
    // Render the selection screen directly. The app now boots into SplashScreen
    // (an async session bootstrap that hits the network), so pumping EdvRouteApp
    // would sit on the splash spinner and never reach selection. This test targets
    // the selection UI itself.
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const UserTypeSelectionScreen()),
    );
    await tester.pumpAndSettle();

    // Passenger mode went LIVE with the client app (fase C-b): no more badge.
    expect(find.text('Próximamente'), findsNothing);
    // Both mode names are rendered.
    expect(find.textContaining('conductor'), findsWidgets);
    expect(find.textContaining('pasajero'), findsWidgets);
  });
}
