/// The alta's cost catalog for the payment summary: the current membership and
/// the tariff the alta charges (weekly for now). Prices arrive from the backend
/// as strings (numeric columns) and are parsed to doubles here. Mirrors the
/// panel's /memberships/current + /subscription-plans data.
class MembershipInfo {
  final String name;
  final double priceUsd;

  const MembershipInfo({required this.name, required this.priceUsd});

  factory MembershipInfo.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim();
    return MembershipInfo(
      name: (name != null && name.isNotEmpty) ? name : 'Membresía',
      priceUsd: double.tryParse('${json['priceUsd']}') ?? 0,
    );
  }
}

/// A subscription plan (tariff). The app charges the weekly one at the alta.
class TariffPlan {
  final int id;
  final String name;
  final double priceUsd;
  final String billingPeriod; // daily | weekly | monthly | annual

  const TariffPlan({
    required this.id,
    required this.name,
    required this.priceUsd,
    required this.billingPeriod,
  });

  factory TariffPlan.fromJson(Map<String, dynamic> json) => TariffPlan(
        id: json['id'] as int,
        name: (json['name'] as String?) ?? 'Tarifa',
        priceUsd: double.tryParse('${json['priceUsd']}') ?? 0,
        billingPeriod: (json['billingPeriod'] as String?) ?? 'weekly',
      );
}
