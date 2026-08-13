// The driver's alta/arrears debt for the app's deferred payment screen (mirrors
// the backend `AppDebt` from GET /driver-auth/me/debt): the total owed, a
// per-line breakdown (membership, tariff weeks, penalty) and whether a payment
// is already awaiting admin review.

/// One line of the debt breakdown.
class AltaDebtItem {
  final String label;
  final double amountUsd;

  const AltaDebtItem({required this.label, required this.amountUsd});

  factory AltaDebtItem.fromJson(Map<String, dynamic> json) => AltaDebtItem(
        label: (json['label'] as String?) ?? '',
        amountUsd: double.tryParse('${json['amountUsd']}') ?? 0,
      );
}

/// The whole debt the app needs to show and settle.
class AltaDebt {
  final double totalUsd;
  final List<AltaDebtItem> items;
  final bool hasPendingPayment;

  const AltaDebt({
    required this.totalUsd,
    required this.items,
    required this.hasPendingPayment,
  });

  bool get hasDebt => totalUsd > 0;

  String get totalLabel => '\$${totalUsd.toStringAsFixed(2)}';

  factory AltaDebt.fromJson(Map<String, dynamic> json) => AltaDebt(
        totalUsd: double.tryParse('${json['totalUsd']}') ?? 0,
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => AltaDebtItem.fromJson(e.cast<String, dynamic>()))
            .toList(),
        hasPendingPayment: json['hasPendingPayment'] as bool? ?? false,
      );
}
