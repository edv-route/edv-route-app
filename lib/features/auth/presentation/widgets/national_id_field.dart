import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_colors.dart';

/// Cédula input: a V/E/J document-type selector next to a digits field, matching
/// how the admin stores `national_id` (canonical form `[VEJ]-<digits>`). The
/// caller owns the [type] (via [onTypeChanged]) and the digits ([controller]),
/// and composes the value as `"$type-${controller.text}"`.
///
/// [locked] disables the type selector at "V" (only V is offered for now), the
/// same way the admin's person form locks its document-type select on register.
class NationalIdField extends StatelessWidget {
  final String type;
  final ValueChanged<String> onTypeChanged;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final String label;
  final String hintText;
  final bool locked;

  const NationalIdField({
    super.key,
    required this.type,
    required this.onTypeChanged,
    required this.controller,
    this.validator,
    this.onFieldSubmitted,
    this.label = 'Cédula',
    this.hintText = 'Número de cédula',
    this.locked = false,
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
            _TypeSelector(value: type, onChanged: onTypeChanged, locked: locked),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                validator: validator,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: onFieldSubmitted,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(hintText: hintText),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool locked;

  const _TypeSelector({required this.value, required this.onChanged, this.locked = false});

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
          // Locked to "V": a null callback disables the dropdown, mirroring the
          // admin's `[disabled]="true"` document-type select.
          onChanged: locked ? null : (v) => onChanged(v ?? value),
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          // Inherit the app font (Montserrat) from the theme instead of a bare
          // TextStyle, whose null fontFamily would fall back to the platform font.
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
          // A disabled DropdownButton greys the selected label via
          // disabledHint; keep it readable and on-brand.
          disabledHint: Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'V', child: Text('V')),
            DropdownMenuItem(value: 'E', child: Text('E')),
            DropdownMenuItem(value: 'J', child: Text('J')),
          ],
        ),
      ),
    );
  }
}
