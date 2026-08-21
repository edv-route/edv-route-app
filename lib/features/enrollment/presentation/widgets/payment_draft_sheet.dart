import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/payment_method_option.dart';
import '../../../../domain/entities/registration_drafts.dart';
import './draft_sheet_scaffold.dart';
import './payment_form.dart';

/// Opens the alta payment as a bottom-sheet (the app equivalent of the panel's
/// payment modal): the total to pay pinned on top + the payment capture form.
/// Returns the captured [PaymentDraftItem], or null if dismissed.
/// [onSubmit] sends the payment FROM INSIDE the sheet: the button spins, the
/// sheet cannot be dismissed, and it only closes once the server has answered.
/// Return an error message to keep it open with the message shown, or null on
/// success. Without it the sheet just pops the captured payment — which is what
/// the registration wizard needs, since there the draft is collected, not sent.
typedef PaymentSubmit = Future<String?> Function(PaymentDraftItem item);

Future<PaymentDraftItem?> showPaymentSheet(
  BuildContext context, {
  required List<PaymentMethodOption> methods,
  required String? totalLabel,
  PaymentDraftItem? initial,
  String? subtitle,
  PaymentSubmit? onSubmit,
}) {
  return showDraftSheet<PaymentDraftItem>(
    context,
    (_) => _PaymentDraftSheet(
      methods: methods,
      totalLabel: totalLabel,
      initial: initial,
      subtitle: subtitle,
      onSubmit: onSubmit,
    ),
  );
}

class _PaymentDraftSheet extends StatefulWidget {
  final List<PaymentMethodOption> methods;
  final String? totalLabel;
  final PaymentDraftItem? initial;
  final String? subtitle;
  final PaymentSubmit? onSubmit;

  const _PaymentDraftSheet({
    required this.methods,
    required this.totalLabel,
    this.initial,
    this.subtitle,
    this.onSubmit,
  });

  @override
  State<_PaymentDraftSheet> createState() => _PaymentDraftSheetState();
}

class _PaymentDraftSheetState extends State<_PaymentDraftSheet> {
  final _formKey = GlobalKey<PaymentFormState>();
  String? _error;
  bool _busy = false;

  Future<void> _confirm() async {
    final result = _formKey.currentState?.readAndValidate();
    if (result == null || result.error != null) {
      setState(() => _error = result?.error ?? 'Completa los datos del pago.');
      return;
    }
    final send = widget.onSubmit;
    if (send == null) {
      Navigator.of(context).pop(result.item);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final failure = await send(result.item!);
    if (!mounted) return;
    // A failure keeps the sheet OPEN with everything he typed still there:
    // closing it would make him fill the whole form again to retry.
    if (failure != null) {
      setState(() {
        _busy = false;
        _error = failure;
      });
      return;
    }
    Navigator.of(context).pop(result.item);
  }

  @override
  Widget build(BuildContext context) {
    return DraftSheetScaffold(
      title: 'Datos del pago',
      subtitle: widget.subtitle ??
          'Registra cómo pagaste el alta. Un administrador lo revisará.',
      confirmLabel: 'Reportar pago',
      canConfirm: true,
      errorText: _error,
      busy: _busy,
      onConfirm: _confirm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.totalLabel != null) ...[
            _TotalBanner(widget.totalLabel!),
            const SizedBox(height: 16),
          ],
          PaymentForm(key: _formKey, paymentMethods: widget.methods, initial: widget.initial),
        ],
      ),
    );
  }
}

/// The "Total a pagar" banner at the top of the payment sheet (mirrors the panel
/// modal header).
class _TotalBanner extends StatelessWidget {
  final String total;

  const _TotalBanner(this.total);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.gold50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold200),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Total a pagar', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold900)),
          ),
          Text(
            total,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gold900),
          ),
        ],
      ),
    );
  }
}
