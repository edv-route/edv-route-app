/// The driver's account standing (GET /driver-auth/me/account): until when his
/// tariff is covered, which charge comes next, and how deep his arrears are.
///
/// [upcoming] and [nextChargeAt] are mutually exclusive by construction: either
/// the next weekly charge is already issued (and can be paid in advance), or it
/// is not yet, and then the backend tells WHEN the engine will issue it.
class AccountStatus {
  /// Authoritative standing kept by the debt engine (`approved`, `overdue`,
  /// `penalized`, `paused`...). The app renders the badge from this, not from
  /// the debt total.
  final String driverStatus;

  /// Penalized but already settled: when the office lets him operate again.
  final DateTime? reactivatesAt;

  /// End of the last prepaid week. Null when he has never paid a week.
  final DateTime? paidUntil;

  /// Charge already issued and not yet due — payable in advance.
  final UpcomingCharge? upcoming;

  /// When the engine will ISSUE the next weekly charge (weekly active tariffs).
  final DateTime? nextChargeAt;

  final int weeksOwed;
  final int penaltyCount;

  /// Weeks of arrears tolerated before the account is penalized.
  final int capWeeks;

  /// Price of the tariff, to announce the amount of a charge not yet issued.
  final double? planPriceUsd;

  const AccountStatus({
    required this.driverStatus,
    this.reactivatesAt,
    this.paidUntil,
    this.upcoming,
    this.nextChargeAt,
    this.weeksOwed = 0,
    this.penaltyCount = 0,
    this.capWeeks = 2,
    this.planPriceUsd,
  });

  bool get isPenalized => driverStatus == 'penalized';
  bool get isOverdue => driverStatus == 'overdue';
  bool get isPaused => driverStatus == 'paused';

  /// Settled his debt but still blocked until the reactivation moment arrives.
  bool get awaitingReactivation =>
      isPenalized && weeksOwed == 0 && penaltyCount == 0 && reactivatesAt != null;

  /// Amount of the next charge: the issued one, or the tariff price when the
  /// engine has not issued it yet.
  double? get nextAmountUsd => upcoming?.amountUsd ?? planPriceUsd;

  /// When the driver next has to pay: the start of the issued charge's period,
  /// or the day the engine will issue it.
  DateTime? get nextChargeDate => upcoming != null ? upcoming!.periodStart : nextChargeAt;

  static AccountStatus fromJson(Map<String, dynamic> json) => AccountStatus(
        driverStatus: json['driverStatus'] as String? ?? 'unknown',
        reactivatesAt: _date(json['reactivatesAt']),
        paidUntil: _date(json['paidUntil']),
        upcoming: json['upcoming'] is Map
            ? UpcomingCharge.fromJson((json['upcoming'] as Map).cast<String, dynamic>())
            : null,
        nextChargeAt: _date(json['nextChargeAt']),
        weeksOwed: (json['weeksOwed'] as num?)?.toInt() ?? 0,
        penaltyCount: (json['penaltyCount'] as num?)?.toInt() ?? 0,
        capWeeks: (json['capWeeks'] as num?)?.toInt() ?? 2,
        planPriceUsd: double.tryParse(json['planPriceUsd'] as String? ?? ''),
      );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}

/// A weekly charge already issued and awaiting payment.
class UpcomingCharge {
  final double amountUsd;
  final DateTime periodStart;
  final DateTime periodEnd;

  const UpcomingCharge({
    required this.amountUsd,
    required this.periodStart,
    required this.periodEnd,
  });

  static UpcomingCharge fromJson(Map<String, dynamic> json) => UpcomingCharge(
        amountUsd: double.tryParse(json['amountUsd'] as String? ?? '') ?? 0,
        periodStart: DateTime.parse(json['periodStart'] as String).toLocal(),
        periodEnd: DateTime.parse(json['periodEnd'] as String).toLocal(),
      );
}
