/// A payment method offered at registration (from `GET /driver-auth/payment-methods`;
/// admin-only methods like cash_usd are excluded by the backend).
class PaymentMethodOption {
  final int id;
  final String name;
  final String type; // e.g. bank_transfer, pago_movil, zelle, binance
  final Map<String, dynamic> details;

  const PaymentMethodOption({
    required this.id,
    required this.name,
    required this.type,
    required this.details,
  });

  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) => PaymentMethodOption(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? '',
        details: (json['details'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}
