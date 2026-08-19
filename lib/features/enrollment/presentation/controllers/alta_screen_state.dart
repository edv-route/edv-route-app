/// What the alta screen must show. Pulled out of the widget so the rule can be
/// tested on its own: routing an affiliate by `status` alone left a `pending`
/// driver WITH DEBT stuck on "solicitud en revisión", unable to pay — which is
/// exactly what a panel registration without payment produces, and what a
/// reverted receipt leaves behind (2026-08-19).
library;

enum AltaScreenState {
  /// He owes money and nothing is under review: show the payment screen.
  pay,

  /// He already sent a payment; an admin has to review it.
  paymentUnderReview,

  /// Owes nothing and is not an affiliate yet: the admin still has to approve him.
  applicationUnderReview,

  /// Owes nothing, approved, but the admin has not set his tariff start yet.
  waitingTariffStart,

  /// Owes nothing, approved and operating: he belongs in the app shell.
  settled,
}

/// Decides that screen. Order matters: a payment under review wins over the debt
/// (he already paid and must not pay twice), and debt wins over everything else
/// (a driver who owes must always be able to settle, whatever his status).
AltaScreenState altaScreenState({
  required bool hasDebt,
  required bool hasPendingPayment,
  required bool justSubmitted,
  required bool isApproved,
  required bool tariffStarted,
}) {
  if (justSubmitted || hasPendingPayment) return AltaScreenState.paymentUnderReview;
  if (hasDebt) return AltaScreenState.pay;
  if (!isApproved) return AltaScreenState.applicationUnderReview;
  if (!tariffStarted) return AltaScreenState.waitingTariffStart;
  return AltaScreenState.settled;
}
