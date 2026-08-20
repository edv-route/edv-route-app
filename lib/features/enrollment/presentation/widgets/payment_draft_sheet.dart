import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/payment_method_option.dart';
import '../../../../domain/entities/registration_drafts.dart';
import './draft_sheet_scaffold.dart';
import './payment_form.dart';

/// Opens the alta payment as a bottom-sheet (the app equivalent of the panel's
/// payment modal): the total to pay pinned on top + the payment capture form.
/// Returns the captured [PaymentDraftItem], or null if dismissed.
Future<PaymentDraftItem?> showPaymentSheet(
  BuildContext context, {
  required List<PaymentMethodOption> methods,
  required String? totalLabel,
  PaymentDraftItem? initial,
}) {
  return showDraftSheet<PaymentDraftItem>(
    context,
    (_) => _PaymentDraftSheet(methods: methods, totalLabel: totalLabel, initial: initial),
  );
}

class _PaymentDraftSheet extends StatefulWidget {
  final List<PaymentMethodOption> methods;
  final String? totalLabel;
  final PaymentDraftItem? initial;

  const _PaymentDraftSheet({required this.methods, required this.totalLabel, this.initial});

  @override
  State<_PaymentDraftSheet> createState() => _PaymentDraftSheetState();
}

class _PaymentDraftSheetState extends State<_PaymentDraftSheet> {
  final _formKey = GlobalKey<PaymentFormState>();
  String? _error;

  void _confirm() {
    final result = _formKey.currentState?.readAndValidate();
    if (result == null || result.error != null) {
      setState(() => _error = result?.error ?? 'Completa los datos del pago.');
      return;
    }
    Navigator.of(context).pop(result.item);
  }

  @override
  Widget build(BuildContext context) {
    return DraftSheetScaffold(
      title: 'Datos del pago',
      subtitle: 'Registra cómo pagaste el alta. Un administrador lo revisará.',
      confirmLabel: 'Reportar pago',
      canConfirm: true,
      errorText: _error,
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
