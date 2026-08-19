import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/features/enrollment/presentation/controllers/alta_screen_state.dart';

/// The rule that decides what an affiliate sees when he opens the app owing (or
/// not owing) money. It exists because routing by `status` alone trapped a
/// `pending` driver WITH DEBT on "solicitud en revisión", with no way to pay.
void main() {
  AltaScreenState state({
    bool hasDebt = false,
    bool hasPendingPayment = false,
    bool justSubmitted = false,
    bool isApproved = true,
    bool tariffStarted = true,
  }) =>
      altaScreenState(
        hasDebt: hasDebt,
        hasPendingPayment: hasPendingPayment,
        justSubmitted: justSubmitted,
        isApproved: isApproved,
        tariffStarted: tariffStarted,
      );

  group('a driver who owes money can always pay', () {
    test('pending with debt goes to the payment screen, not to the review notice', () {
      // The regression: a panel registration without payment, and a driver whose
      // receipt was reverted because the money bounced.
      expect(
        state(hasDebt: true, isApproved: false, tariffStarted: false),
        AltaScreenState.pay,
      );
    });

    test('approved with debt goes to the payment screen', () {
      expect(state(hasDebt: true, tariffStarted: false), AltaScreenState.pay);
    });

    test('debt wins over a tariff that never started', () {
      expect(state(hasDebt: true, isApproved: true, tariffStarted: false), AltaScreenState.pay);
    });
  });

  group('a payment already sent wins over the debt (never pay twice)', () {
    test('a pending submission shows the review state even while he owes', () {
      expect(
        state(hasDebt: true, hasPendingPayment: true),
        AltaScreenState.paymentUnderReview,
      );
    });

    test('just submitted shows the review state before the backend catches up', () {
      expect(
        state(hasDebt: true, justSubmitted: true),
        AltaScreenState.paymentUnderReview,
      );
    });
  });

  group('owing nothing', () {
    test('pending and owing nothing waits for the admin', () {
      expect(
        state(isApproved: false, tariffStarted: false),
        AltaScreenState.applicationUnderReview,
      );
    });

    test('approved, settled, tariff not started yet waits for the start date', () {
      expect(state(tariffStarted: false), AltaScreenState.waitingTariffStart);
    });

    test('approved, settled and started belongs in the app', () {
      expect(state(), AltaScreenState.settled);
    });
  });
}
