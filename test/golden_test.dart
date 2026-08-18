import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/features/auth/presentation/screens/driver_login_screen.dart';
import 'package:edv_route_mobile/features/auth/presentation/screens/user_type_selection_screen.dart';
import 'package:edv_route_mobile/theme/app_theme.dart';

/// Renders a STATIC auth screen at a phone resolution and captures a PNG golden.
/// Regenerate with: `flutter test --update-goldens test/golden_test.dart`.
///
/// Note: DriverShell / ProfileScreen are no longer here — once the profile started
/// loading account data (debt, checklist, benefits) over the network it stopped
/// being a pure golden-able widget; testing it needs a faked repository (TODO).
Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(1170, 2532); // iPhone-class @3x
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: screen,
    ),
  );

  // Force asset images (the logo) to decode so they appear in the golden.
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('golden: user type selection', (tester) async {
    await _pumpScreen(tester, const UserTypeSelectionScreen());
    await expectLater(
      find.byType(UserTypeSelectionScreen),
      matchesGoldenFile('goldens/selection.png'),
    );
  });

  testWidgets('golden: driver login', (tester) async {
    await _pumpScreen(tester, const DriverLoginScreen());
    await expectLater(
      find.byType(DriverLoginScreen),
      matchesGoldenFile('goldens/driver_login.png'),
    );
  });
}
