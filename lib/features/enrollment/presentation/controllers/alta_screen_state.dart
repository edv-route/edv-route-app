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

  /// Report-payment screen only: there is nothing to pay right now.
  nothingOwed,
}

/// What the REPORT-PAYMENT screen shows when an affiliate who is already inside
/// the app opens it from his profile.
///
/// A different question from [altaScreenState], and that is why it is a
/// different function: the entrance asks "where does this driver belong?", this
/// one asks "what is there to pay?". Answering both with one rule is what turned
/// a payment into a locked door.
AltaScreenState reportPaymentState({
  required bool hasDebt,
  required bool hasPendingPayment,
  required bool justSubmitted,
}) {
  if (justSubmitted || hasPendingPayment) return AltaScreenState.paymentUnderReview;
  if (hasDebt) return AltaScreenState.pay;
  return AltaScreenState.nothingOwed;
}

/// Decides that screen.
///
/// The FIRST rule is the important one: an affiliate whose tariff already
/// started is INSIDE the app, and nothing on this screen may hold him there.
/// Until 2026-08-21 a "payment under review" outranked everything, so a driver
/// who had been working for weeks reported a payment and was thrown onto a
/// waiting screen whose only button was «Cerrar sesión» — locked out of his own
/// account until an admin got around to reviewing him. Reporting a payment is
/// something he does INSIDE the app, not a door that closes behind him.
///
/// It is the same trap that caught `pending` drivers on 2026-08-19, one door
/// further in: routing by a single flag instead of asking whether he is already
/// an affiliate.
///
/// After that, order still matters: a payment under review wins over the debt
/// (he already paid and must not pay twice), and debt wins over the rest — a
/// driver who owes must always be able to settle, whatever his status.
AltaScreenState altaScreenState({
  required bool hasDebt,
  required bool hasPendingPayment,
  required bool justSubmitted,
  required bool isApproved,
  required bool tariffStarted,
}) {
  // Already operating: he belongs in the shell, debt or no debt, review or no
  // review. `tariffStarted` is the solid signal — the admin can only set the
  // start once the alta is settled, so it means "he is in".
  if (isApproved && tariffStarted) return AltaScreenState.settled;

  if (justSubmitted || hasPendingPayment) return AltaScreenState.paymentUnderReview;
  if (hasDebt) return AltaScreenState.pay;
  if (!isApproved) return AltaScreenState.applicationUnderReview;
  return AltaScreenState.waitingTariffStart;
}
