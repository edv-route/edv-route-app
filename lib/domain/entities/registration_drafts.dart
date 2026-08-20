import './picked_image.dart';

/// A payment captured in the wizard: the method + payer metadata + one receipt.
/// [methodLabel] is kept so the summary card can show the method without a lookup.
class PaymentDraftItem {
  final int paymentMethodId;
  final String methodLabel;
  final String? reference;
  final String? payerBank;
  final String paidOn; // ISO yyyy-MM-dd
  final String? payerPhone;
  final String? payerId;
  final String? payerAccount;
  final PickedImage receipt;

  const PaymentDraftItem({
    required this.paymentMethodId,
    required this.methodLabel,
    this.reference,
    this.payerBank,
    required this.paidOn,
    this.payerPhone,
    this.payerId,
    this.payerAccount,
    required this.receipt,
  });
}
