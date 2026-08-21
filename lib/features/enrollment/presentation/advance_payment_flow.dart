import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/account_status.dart';
import '../../../domain/repositories/enrollment_repository.dart' show PaymentCapture;
import 'widgets/advance_weeks_sheet.dart';
import 'widgets/payment_draft_sheet.dart';

/// Prepaying weeks, end to end: how many → the usual payment sheet → submit.
///
/// A FLOW, not a screen. The first attempt put a confirmation screen between the
/// two sheets and it was a step that decided nothing: the driver had already
/// chosen his weeks and seen the total in the sheet, so the screen only asked him
/// to look at the same numbers again (2026-08-21).
///
/// It reuses `showPaymentSheet` — the very same modal the alta and the debt use.
/// A second payment form would be a third copy of the same review, which is the
/// mistake this project already made once with the solicitudes.
///
/// Returns true when a payment was submitted.
Future<bool> runAdvancePaymentFlow(
  BuildContext context, {
  required AccountStatus account,
  /// Reloads the caller's screen. Awaited BEFORE the sheet closes, so the state
  /// behind it is already fresh when it comes into view.
  Future<void> Function()? onSubmitted,
}) async {
  final weeklyTariff = account.planPriceUsd;
  if (weeklyTariff == null) return false;

  // The price comes from the ACCOUNT, never from the debt breakdown: an affiliate
  // who is up to date has no debt lines, so reading the weekly amount from there
  // quoted him $0.00 for two weeks.
  final weeks = await pickAdvanceWeeks(
    context,
    weeklyTariff: weeklyTariff,
    paidUntil: account.paidUntil,
  );
  if (weeks == null || !context.mounted) return false;

  final catalogs = Dependencies.instance.catalogsRepository;
  final methods = await catalogs.loadPaymentMethods().catchError((_) => _noMethods);
  if (!context.mounted) return false;
  if (methods.isEmpty) {
    _say(context, 'No hay métodos de pago disponibles en este momento.');
    return false;
  }

  // The send happens INSIDE the sheet: the button spins, it cannot be dismissed
  // mid-flight, and it closes only once the server answered. Popping first and
  // submitting after left the driver staring at his profile with no sign that
  // anything was happening (2026-08-21).
  final item = await showPaymentSheet(
    context,
    methods: methods,
    totalLabel: formatUsd(weeklyTariff * weeks),
    subtitle: 'Registra cómo pagaste. Un administrador lo revisará.',
    onSubmit: (captured) async {
      try {
        await Dependencies.instance.enrollmentRepository.submitPayment(
          PaymentCapture(
            paymentMethodId: captured.paymentMethodId,
            reference: captured.reference,
            payerBank: captured.payerBank,
            paidOn: captured.paidOn,
            payerPhone: captured.payerPhone,
            payerId: captured.payerId,
            payerAccount: captured.payerAccount,
            receipt: captured.receipt,
          ),
          // He accepted them at his alta and the backend has the date stamped;
          // asking an affiliate who has been working for months to tick the box
          // again on every weekly payment is friction that decides nothing.
          acceptedTerms: true,
          weeks: weeks,
          advance: true,
        );
      } on ApiException catch (e) {
        return e.message;
      } catch (_) {
        return 'No se pudo registrar el pago. Intenta de nuevo.';
      }
      // Refreshed BEFORE the sheet closes, so what appears behind it is already
      // the new state — never the old card for a blink.
      await onSubmitted?.call();
      return null;
    },
  );
  if (item == null) return false;

  if (context.mounted) {
    _say(context, 'Recibimos tu pago. Un administrador lo revisará.');
  }
  return true;
}

const _noMethods = <Never>[];

void _say(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
