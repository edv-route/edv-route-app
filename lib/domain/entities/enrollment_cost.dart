/// A single membership benefit shown on the informational pre-screen.
class MembershipBenefit {
  final int id;
  final String name;
  final String? description;

  const MembershipBenefit({required this.id, required this.name, this.description});

  factory MembershipBenefit.fromJson(Map<String, dynamic> json) {
    final description = (json['description'] as String?)?.trim();
    return MembershipBenefit(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      description: (description != null && description.isNotEmpty) ? description : null,
    );
  }
}

/// The alta's cost catalog for the payment summary: the current membership (with
/// its benefits, for the informational pre-screen) and the tariff the alta
/// charges (weekly for now). Prices arrive from the backend as strings (numeric
/// columns) and are parsed to doubles here. Mirrors the panel's
/// /memberships/current + /subscription-plans data.
class MembershipInfo {
  final String name;
  final double priceUsd;
  final List<MembershipBenefit> benefits;

  const MembershipInfo({
    required this.name,
    required this.priceUsd,
    this.benefits = const [],
  });

  factory MembershipInfo.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim();
    final rawBenefits = json['benefits'];
    return MembershipInfo(
      name: (name != null && name.isNotEmpty) ? name : 'Membresía',
      priceUsd: double.tryParse('${json['priceUsd']}') ?? 0,
      benefits: rawBenefits is List
          ? rawBenefits
              .whereType<Map>()
              .map((e) => MembershipBenefit.fromJson(e.cast<String, dynamic>()))
              .where((b) => b.name.isNotEmpty)
              .toList()
          : const [],
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
