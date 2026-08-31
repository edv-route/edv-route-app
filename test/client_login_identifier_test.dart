import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/features/client/auth/presentation/controllers/client_login_controller.dart';

void main() {
  group('ClientLoginController.normalizeIdentifier', () {
    // The backend compares the phone EXACTLY against the stored E.164 value
    // (+58XXXXXXXXXX). Every human way of typing a Venezuelan mobile number
    // must land on that shape, or login by phone silently never matches.
    test('emails pass through untouched', () {
      expect(
        ClientLoginController.normalizeIdentifier(' luis@ejemplo.com '),
        'luis@ejemplo.com',
      );
    });

    test('national format with leading 0', () {
      expect(ClientLoginController.normalizeIdentifier('04121234567'), '+584121234567');
      expect(ClientLoginController.normalizeIdentifier('0412 123 4567'), '+584121234567');
      expect(ClientLoginController.normalizeIdentifier('0412-123-45-67'), '+584121234567');
    });

    test('already E.164, with or without the plus', () {
      expect(ClientLoginController.normalizeIdentifier('+584121234567'), '+584121234567');
      expect(ClientLoginController.normalizeIdentifier('584121234567'), '+584121234567');
      expect(ClientLoginController.normalizeIdentifier('+58 412 123 4567'), '+584121234567');
    });

    test('typed without the leading 0', () {
      expect(ClientLoginController.normalizeIdentifier('4121234567'), '+584121234567');
    });

    test('anything else passes through for the backend to reject', () {
      expect(ClientLoginController.normalizeIdentifier('12345'), '12345');
      expect(ClientLoginController.normalizeIdentifier('no-es-nada'), 'no-es-nada');
    });
  });
}
