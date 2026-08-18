import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/features/auth/domain/entities/account_status.dart';
import 'package:edv_route_mobile/features/auth/domain/entities/driver.dart';

void main() {
  group('AccountStatus.fromJson', () {
    test('reads the standing, the coverage and the issued charge', () {
      final account = AccountStatus.fromJson({
        'driverStatus': 'overdue',
        'reactivatesAt': null,
        'paidUntil': '2026-08-24T04:00:00.000Z',
        'upcoming': {
          'amountUsd': '10.00',
          'periodStart': '2026-08-24T04:00:00.000Z',
          'periodEnd': '2026-08-31T04:00:00.000Z',
        },
        'nextChargeAt': null,
        'weeksOwed': 1,
        'penaltyCount': 0,
        'capWeeks': 2,
        'planPriceUsd': '10.00',
      });

      expect(account.driverStatus, 'overdue');
      expect(account.isOverdue, isTrue);
      expect(account.weeksOwed, 1);
      expect(account.paidUntil, isNotNull);
      expect(account.upcoming!.amountUsd, 10.0);
    });

    test('survives a payload with everything null (driver without a tariff)', () {
      final account = AccountStatus.fromJson({
        'driverStatus': 'approved',
        'reactivatesAt': null,
        'paidUntil': null,
        'upcoming': null,
        'nextChargeAt': null,
        'weeksOwed': 0,
        'penaltyCount': 0,
        'capWeeks': 2,
        'planPriceUsd': null,
      });

      expect(account.paidUntil, isNull);
      expect(account.nextChargeDate, isNull);
      expect(account.nextAmountUsd, isNull);
      expect(account.awaitingReactivation, isFalse);
    });
  });

  group('next charge', () {
    // An ISSUED charge is payable now; a charge not issued yet is only announced,
    // and then the amount comes from the tariff price.
    test('an issued charge takes precedence over the emission date', () {
      final account = AccountStatus.fromJson({
        'driverStatus': 'approved',
        'upcoming': {
          'amountUsd': '10.00',
          'periodStart': '2026-08-24T04:00:00.000Z',
          'periodEnd': '2026-08-31T04:00:00.000Z',
        },
        'nextChargeAt': '2026-08-21T22:00:00.000Z',
        'planPriceUsd': '10.00',
      });

      expect(account.nextAmountUsd, 10.0);
      expect(account.nextChargeDate, account.upcoming!.periodStart);
    });

    test('with no issued charge it announces the emission at the tariff price', () {
      final account = AccountStatus.fromJson({
        'driverStatus': 'approved',
        'upcoming': null,
        'nextChargeAt': '2026-08-21T22:00:00.000Z',
        'planPriceUsd': '12.50',
      });

      expect(account.nextAmountUsd, 12.5);
      expect(account.nextChargeDate, account.nextChargeAt);
    });
  });

  group('penalized', () {
    test('settled but still blocked = awaiting reactivation', () {
      final account = AccountStatus.fromJson({
        'driverStatus': 'penalized',
        'reactivatesAt': '2026-08-25T12:00:00.000Z',
        'weeksOwed': 0,
        'penaltyCount': 0,
      });

      expect(account.isPenalized, isTrue);
      expect(account.awaitingReactivation, isTrue);
    });

    test('penalized WITH debt is not awaiting reactivation: he must pay first', () {
      final account = AccountStatus.fromJson({
        'driverStatus': 'penalized',
        'reactivatesAt': '2026-08-25T12:00:00.000Z',
        'weeksOwed': 3,
        'penaltyCount': 1,
      });

      expect(account.awaitingReactivation, isFalse);
    });
  });

  group('DriverStatus.fromApi', () {
    // These used to collapse into `unknown`, which showed a driver in arrears
    // exactly like a driver up to date.
    test('maps the states written by the debt engine', () {
      expect(DriverStatus.fromApi('overdue'), DriverStatus.overdue);
      expect(DriverStatus.fromApi('penalized'), DriverStatus.penalized);
      expect(DriverStatus.fromApi('paused'), DriverStatus.paused);
      expect(DriverStatus.fromApi('scheduled'), DriverStatus.scheduled);
      expect(DriverStatus.fromApi('vaya-usted-a-saber'), DriverStatus.unknown);
    });

    test('an overdue driver still operates; a penalized one does not', () {
      expect(DriverStatus.overdue.canOperate, isTrue);
      expect(DriverStatus.approved.canOperate, isTrue);
      expect(DriverStatus.penalized.canOperate, isFalse);
      expect(DriverStatus.paused.canOperate, isFalse);
    });
  });
}
