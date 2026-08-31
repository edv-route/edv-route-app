import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Privacy-consent checkbox required to register (both channels). Turns red
/// when submit is attempted without it (mirrors the field-level validation).
class PrivacyCheck extends StatelessWidget {
  final bool value;
  final bool error;
  final ValueChanged<bool> onChanged;

  const PrivacyCheck({
    super.key,
    required this.value,
    required this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'He leído y acepto la Política de Privacidad.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
        if (error)
          const Padding(
            padding: EdgeInsets.only(left: 34, top: 2),
            child: Text(
              'Debes aceptar la política de privacidad para continuar.',
              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
