// The driver's alta/arrears debt for the app's deferred payment screen (mirrors
// the backend `AppDebt` from GET /driver-auth/me/debt): the total owed, a
// per-line breakdown (membership, tariff weeks, penalty) and whether a payment
// is already awaiting admin review.

import '../../core/utils/money.dart';

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

/// His last payment was turned down. Until this existed the app said nothing:
/// the payment screen simply came back, so the driver had no way of knowing he
/// had been rejected — let alone why — and resent the same proof.
class AltaDebtRejection {
  final double amountUsd;
  final String? reason;
  final DateTime? reviewedAt;

  const AltaDebtRejection({required this.amountUsd, this.reason, this.reviewedAt});

  String get amountLabel => formatUsd(amountUsd);

  factory AltaDebtRejection.fromJson(Map<String, dynamic> json) => AltaDebtRejection(
        amountUsd: double.tryParse('${json['amountUsd']}') ?? 0,
        reason: (json['reason'] as String?)?.trim().isEmpty ?? true
            ? null
            : (json['reason'] as String).trim(),
        reviewedAt: DateTime.tryParse('${json['reviewedAt']}')?.toLocal(),
      );
}

/// The whole debt the app needs to show and settle.
class AltaDebt {
  final double totalUsd;
  final List<AltaDebtItem> items;
  final bool hasPendingPayment;

  /// Set while his LAST submission is a rejected one; the backend clears it by
  /// itself as soon as he sends a new payment.
  final AltaDebtRejection? rejected;

  const AltaDebt({
    required this.totalUsd,
    required this.items,
    required this.hasPendingPayment,
    this.rejected,
  });

  bool get hasDebt => totalUsd > 0;

  String get totalLabel => formatUsd(totalUsd);

  /// The weekly tariff amount from the breakdown (the "Tarifa de la semana" line),
  /// used to price advance weeks (Forma A). Null when there is no weekly line
  /// (then advancing weeks is not offered).
  double? get weeklyTariffUsd {
    for (final it in items) {
      if (it.label.toLowerCase().contains('semana')) return it.amountUsd;
    }
    return null;
  }

  factory AltaDebt.fromJson(Map<String, dynamic> json) => AltaDebt(
        totalUsd: double.tryParse('${json['totalUsd']}') ?? 0,
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => AltaDebtItem.fromJson(e.cast<String, dynamic>()))
            .toList(),
        hasPendingPayment: json['hasPendingPayment'] as bool? ?? false,
        rejected: json['rejected'] is Map
            ? AltaDebtRejection.fromJson(
                (json['rejected'] as Map).cast<String, dynamic>(),
              )
            : null,
      );
}
