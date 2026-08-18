import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// A Venezuelan mobile operator code: the 3 digits after +58. The [label] shows
/// the local "0xxx" form; the [code] is the E.164 fragment without the leading 0.
class PhoneOperator {
  final String code;
  final String label;
  const PhoneOperator(this.code, this.label);
}

/// Mirrors the admin's `PHONE_OPERATOR_OPTIONS` (person-form.ts). The composed
/// phone is `+58` + [PhoneOperator.code] + a 7-digit local number.
const kPhoneOperators = <PhoneOperator>[
  PhoneOperator('412', '0412'),
  PhoneOperator('422', '0422'),
  PhoneOperator('414', '0414'),
  PhoneOperator('424', '0424'),
  PhoneOperator('416', '0416'),
  PhoneOperator('426', '0426'),
];

/// Phone input matching the admin panel: a locked "+58" country box, a mobile
/// operator selector (0412/0422/0414/0424/0416/0426) and a 7-digit local number.
/// The caller owns the [operator] code (via [onOperatorChanged]) and the digits
/// ([controller]), and composes the value as `"+58${operator}${controller.text}"`.
class OperatorPhoneField extends StatelessWidget {
  final String label;
  final String operator;
  final ValueChanged<String> onOperatorChanged;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  const OperatorPhoneField({
    super.key,
    required this.label,
    required this.operator,
    required this.onOperatorChanged,
    required this.controller,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.primary900,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code: only +58 for now, shown locked (like the admin's
            // disabled country select).
            const _CountryBox(),
            const SizedBox(width: 8),
            _OperatorSelector(value: operator, onChanged: onOperatorChanged),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                validator: validator,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: onFieldSubmitted,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: const InputDecoration(hintText: '1234567'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The locked "+58" prefix box, styled like the grey selector boxes.
class _CountryBox extends StatelessWidget {
  const _CountryBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        '+58',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.muted),
      ),
    );
  }
}

/// The mobile operator dropdown (grey box, matching [NationalIdField]'s style).
class _OperatorSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _OperatorSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: (v) => onChanged(v ?? value),
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
          items: [
            for (final o in kPhoneOperators)
              DropdownMenuItem(value: o.code, child: Text(o.label)),
          ],
        ),
      ),
    );
  }
}
