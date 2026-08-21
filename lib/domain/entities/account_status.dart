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

  /// His start is PROGRAMMED for this date and hasn't arrived (2026-08-20).
  /// Null once the tariff is running. Until this existed the app could only say
  /// he was not enabled to work, never that he already had a date.
  final DateTime? tariffStartsAt;

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

  /// Unread notices, for the bell in the header. It travels INSIDE this call,
  /// which every screen already makes, and never in a request of its own: a
  /// second call that fails without a signal would leave the bell showing a
  /// stale number while the rest of the screen is fresh.
  final int unreadNotifications;

  /// Weeks he may prepay from the app. Comes from the SERVER so the wheel can
  /// never offer a number the backend would refuse — the app must not carry its
  /// own copy of a business limit.
  final int maxAdvanceWeeks;

  const AccountStatus({
    required this.driverStatus,
    this.reactivatesAt,
    this.tariffStartsAt,
    this.paidUntil,
    this.upcoming,
    this.nextChargeAt,
    this.weeksOwed = 0,
    this.penaltyCount = 0,
    this.capWeeks = 2,
    this.planPriceUsd,
    this.unreadNotifications = 0,
    this.maxAdvanceWeeks = 0,
  });

  bool get isPenalized => driverStatus == 'penalized';

  /// Approved with a start date that has not arrived: he is not blocked, he is
  /// early — and there is a day to tell him.
  bool get startsLater => tariffStartsAt != null;

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
        tariffStartsAt: _date(json['tariffStartsAt']),
        paidUntil: _date(json['paidUntil']),
        upcoming: json['upcoming'] is Map
            ? UpcomingCharge.fromJson((json['upcoming'] as Map).cast<String, dynamic>())
            : null,
        nextChargeAt: _date(json['nextChargeAt']),
        weeksOwed: (json['weeksOwed'] as num?)?.toInt() ?? 0,
        penaltyCount: (json['penaltyCount'] as num?)?.toInt() ?? 0,
        capWeeks: (json['capWeeks'] as num?)?.toInt() ?? 2,
        planPriceUsd: double.tryParse(json['planPriceUsd'] as String? ?? ''),
        unreadNotifications: (json['unreadNotifications'] as num?)?.toInt() ?? 0,
        maxAdvanceWeeks: (json['maxAdvanceWeeks'] as num?)?.toInt() ?? 0,
      );

  /// Same standing with a fresh unread count, for when the inbox reports back
  /// what it left behind. Rebuilding the bell must not cost another round trip.
  AccountStatus withUnread(int unread) => AccountStatus(
        driverStatus: driverStatus,
        reactivatesAt: reactivatesAt,
        tariffStartsAt: tariffStartsAt,
        paidUntil: paidUntil,
        upcoming: upcoming,
        nextChargeAt: nextChargeAt,
        weeksOwed: weeksOwed,
        penaltyCount: penaltyCount,
        capWeeks: capWeeks,
        planPriceUsd: planPriceUsd,
        unreadNotifications: unread,
        maxAdvanceWeeks: maxAdvanceWeeks,
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
