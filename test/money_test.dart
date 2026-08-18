import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/core/utils/money.dart';

void main() {
  group('formatUsd', () {
    test('always two decimals', () {
      expect(formatUsd(10), r'$10.00');
      expect(formatUsd(12.5), r'$12.50');
      expect(formatUsd(180.456), r'$180.46');
      expect(formatUsd(0), r'$0.00');
    });

    // The escaped dollar right before an interpolation is easy to get wrong, and
    // when it is wrong the app prints the formula. A real driver saw
    // "Próximo pago de ${amount.toStringAsFixed(2)}" on 2026-08-18.
    test('never leaks the interpolation itself', () {
      final text = 'Próximo pago de ${formatUsd(10)} el lunes';
      expect(text, 'Próximo pago de \$10.00 el lunes');
      expect(text.contains('toStringAsFixed'), isFalse);
      expect(text.contains(r'${'), isFalse);
    });
  });
}
