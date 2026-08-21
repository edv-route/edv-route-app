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

  final item = await showPaymentSheet(
    context,
    methods: methods,
    totalLabel: formatUsd(weeklyTariff * weeks),
  );
  if (item == null || !context.mounted) return false;

  try {
    await Dependencies.instance.enrollmentRepository.submitPayment(
      PaymentCapture(
        paymentMethodId: item.paymentMethodId,
        reference: item.reference,
        payerBank: item.payerBank,
        paidOn: item.paidOn,
        payerPhone: item.payerPhone,
        payerId: item.payerId,
        payerAccount: item.payerAccount,
        receipt: item.receipt,
      ),
      // He accepted them at his alta and the backend has the date stamped; asking
      // an affiliate who has been working for months to tick the box again on
      // every weekly payment is friction that decides nothing.
      acceptedTerms: true,
      weeks: weeks,
      advance: true,
    );
  } on ApiException catch (e) {
    if (context.mounted) _say(context, e.message);
    return false;
  } catch (_) {
    if (context.mounted) _say(context, 'No se pudo registrar el pago. Intenta de nuevo.');
    return false;
  }

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
