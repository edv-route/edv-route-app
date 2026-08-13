import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/app.dart';

void main() {
  testWidgets('Selection screen shows driver mode active and passenger soon',
      (tester) async {
    await tester.pumpWidget(const EdvRouteApp());
    await tester.pump();

    // Passenger mode is disabled until that side of the product ships.
    expect(find.text('Próximamente'), findsOneWidget);
    // Both mode names are rendered.
    expect(find.textContaining('conductor'), findsWidgets);
    expect(find.textContaining('pasajero'), findsWidgets);
  });
}
