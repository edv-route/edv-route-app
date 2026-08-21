import 'package:flutter/material.dart';

import '../../../../core/utils/date_format.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/brand_text_field.dart';
import '../../../../data/payment_catalogs.dart';
import '../../../../domain/entities/payment_method_option.dart';
import '../../../../domain/entities/picked_image.dart';
import '../../../../domain/entities/registration_drafts.dart';
import '../../../../shared/widgets/media_picker.dart';
import '../../../../shared/widgets/national_id_field.dart';
import '../../../../shared/widgets/registration_fields.dart';

/// Result of validating the inline payment form: the captured payment, or an
/// error message to surface. Exactly one of the two is non-null.
typedef PaymentValidation = ({PaymentDraftItem? item, String? error});

/// Inline single-payment capture for step 4 of registration. Mirrors the admin's
/// `payment-capture` (method + destination account + reference + date + payer
/// details by method + receipt), in the same field order and labels. It is NOT a
/// "list + add" flow — the alta has exactly one payment. The screen reads it with
/// the state's [readAndValidate] when submitting. Efectivo Divisa is admin-only
/// and never reaches here.
class PaymentForm extends StatefulWidget {
  final List<PaymentMethodOption> paymentMethods;
  final PaymentDraftItem? initial;

  const PaymentForm({super.key, required this.paymentMethods, this.initial});

  @override
  State<PaymentForm> createState() => PaymentFormState();
}

class PaymentFormState extends State<PaymentForm> {
  PaymentMethodOption? _method;
  final _reference = TextEditingController();
  final _payerPhone = TextEditingController();
  final _payerIdDigits = TextEditingController();
  final _payerAccount = TextEditingController();
  String _payerIdType = 'V';
  String? _payerBank;
  DateTime? _paidOn;
  PickedImage? _receipt;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    _paidOn = DateTime.now(); // default to today, mirrors the admin's precarga
    final p = widget.initial;
    if (p != null) {
      for (final m in widget.paymentMethods) {
        if (m.id == p.paymentMethodId) {
          _method = m;
          break;
        }
      }
      _reference.text = p.reference ?? '';
      _payerBank = p.payerBank;
      _paidOn = DateTime.tryParse(p.paidOn) ?? _paidOn;
      _payerAccount.text = p.payerAccount ?? '';
      _receipt = p.receipt;
      // Payer phone stored as +58 + 10 digits → shown back as the local 0-form.
      final phone = p.payerPhone;
      if (phone != null && phone.startsWith('+58')) _payerPhone.text = '0${phone.substring(3)}';
      final id = p.payerId;
      if (id != null && id.length >= 2 && id[1] == '-') {
        _payerIdType = id[0];
        _payerIdDigits.text = id.substring(2);
      }
    }
  }

  @override
  void dispose() {
    _reference.dispose();
    _payerPhone.dispose();
    _payerIdDigits.dispose();
    _payerAccount.dispose();
    super.dispose();
  }

  bool _needsReference(String t) => const {'bank_transfer', 'pago_movil', 'zelle', 'binance'}.contains(t);
  bool _needsBank(String t) => const {'bank_transfer', 'pago_movil'}.contains(t);
  bool _needsPayerPhoneId(String t) => t == 'pago_movil';
  bool _needsAccount(String t) => const {'zelle', 'binance'}.contains(t);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidOn ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _paidOn = picked);
  }

  /// The method list used to be printed in full, one card per method, above the
  /// form. With five methods it already pushed everything below the fold, and
  /// the driver had to scroll past all of them to reach the fields — on a sheet
  /// that is itself scrollable. It is a single choice from a closed list, which
  /// is exactly what the picker (already used for the bank) is for.
  Future<void> _pickMethod() async {
    final method = await pickFromSheet<PaymentMethodOption>(
      context,
      title: 'Selecciona el método de pago',
      items: widget.paymentMethods,
      labelOf: (m) => m.name,
    );
    if (method != null) setState(() => _method = method);
  }

  Future<void> _pickBank() async {
    final bank = await pickFromSheet<String>(
      context,
      title: 'Selecciona el banco',
      items: venezuelanBanks,
      labelOf: (b) => b,
    );
    if (bank != null) setState(() => _payerBank = bank);
  }

  Future<void> _capture() async {
    final img = await pickDocument(context);
    if (img != null) setState(() => _receipt = img);
  }

  String? _composePayerPhone() {
    var d = _payerPhone.text.trim();
    if (d.startsWith('0')) d = d.substring(1);
    if (d.length != 10) return null;
    return '+58$d';
  }

  /// Validates the whole payment. Returns the [PaymentDraftItem] on success, or a
  /// human message to show. Called by the screen when submitting.
  PaymentValidation readAndValidate() {
    final m = _method;
    if (m == null) return (item: null, error: 'Elige el método de pago.');
    if (_paidOn == null) return (item: null, error: 'Indica la fecha del pago.');
    final type = m.type;
    if (_needsReference(type) && _reference.text.trim().isEmpty) {
      return (item: null, error: 'Ingresa la referencia del pago.');
    }
    if (_needsBank(type) && (_payerBank == null || _payerBank!.isEmpty)) {
      return (item: null, error: 'Indica el banco emisor.');
    }
    if (_needsPayerPhoneId(type)) {
      if (!RegExp(r'^\d{10,11}$').hasMatch(_payerPhone.text.trim())) {
        return (item: null, error: 'Teléfono del pagador inválido.');
      }
      final id = _payerIdDigits.text.trim();
      if (id.length < 5 || id.length > 9) {
        return (item: null, error: 'Cédula del pagador inválida.');
      }
    }
    if (_needsAccount(type)) {
      final account = _payerAccount.text.trim();
      if (account.isEmpty) return (item: null, error: 'Indica el correo o cuenta del pagador.');
      // Zelle/Binance accounts are usually an email; validate the shape if it
      // looks like one (mirrors the admin's EMAIL_LIKE check).
      if (account.contains('@') && !_emailRegex.hasMatch(account)) {
        return (item: null, error: 'Correo del pagador inválido.');
      }
    }
    if (_receipt == null) return (item: null, error: 'Adjunta el comprobante de pago.');

    return (
      item: PaymentDraftItem(
        paymentMethodId: m.id,
        methodLabel: m.name,
        paidOn: formatApiDate(_paidOn!),
        reference: _needsReference(type) ? _reference.text.trim() : null,
        payerBank: _needsBank(type) ? _payerBank : null,
        payerPhone: _needsPayerPhoneId(type) ? _composePayerPhone() : null,
        payerId: _needsPayerPhoneId(type) ? '$_payerIdType-${_payerIdDigits.text.trim()}' : null,
        payerAccount: _needsAccount(type) ? _payerAccount.text.trim() : null,
        receipt: _receipt!,
      ),
      error: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _method;
    final type = selected?.type ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PickerField(
          label: 'Método de pago',
          value: selected?.name,
          hint: 'Selecciona cómo pagaste',
          onTap: _pickMethod,
        ),
        if (selected != null) ...[
          const SizedBox(height: 6),
          // Destination account of the chosen method (where the driver paid).
          DestinationCard(rows: destinationRows(type, selected.details)),
          if (_needsReference(type)) ...[
            const SizedBox(height: 16),
            BrandTextField(
              label: 'Referencia',
              controller: _reference,
              hintText: 'N° de referencia / confirmación',
              inputFormatters: [
                // Alphanumeric + spaces (mirrors the admin's appAlnum). The app
                // endpoint doesn't run the JSON Schema, so this is the only guard.
                FilteringTextInputFormatter.allow(RegExp(r'[\p{L}\p{N} ]', unicode: true)),
                LengthLimitingTextInputFormatter(25),
              ],
            ),
          ],
          const SizedBox(height: 16),
          DateField(label: 'Fecha del pago', value: _paidOn, onTap: _pickDate),
          if (_needsAccount(type)) ...[
            const SizedBox(height: 14),
            BrandTextField(
              label: 'Correo o nombre del pagador',
              controller: _payerAccount,
              hintText: 'correo@ejemplo.com o nombre de quien pagó',
              keyboardType: TextInputType.emailAddress,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
            ),
          ],
          if (_needsBank(type)) ...[
            const SizedBox(height: 14),
            PickerField(
              label: 'Banco emisor',
              value: _payerBank,
              hint: 'Selecciona el banco',
              onTap: _pickBank,
            ),
          ],
          if (_needsPayerPhoneId(type)) ...[
            const SizedBox(height: 14),
            NationalIdField(
              label: 'Cédula del pagador',
              type: _payerIdType,
              onTypeChanged: (t) => setState(() => _payerIdType = t),
              controller: _payerIdDigits,
            ),
            const SizedBox(height: 14),
            BrandTextField(
              label: 'Teléfono del pagador',
              controller: _payerPhone,
              hintText: 'Ej.: 04121234567',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
          ],
          const SizedBox(height: 18),
          CaptureTile(
            title: 'Comprobante (imagen o PDF)',
            description: 'PNG, JPG o PDF · máx. 10 MB',
            image: _receipt,
            onPick: _capture,
          ),
        ],
      ],
    );
  }
}
