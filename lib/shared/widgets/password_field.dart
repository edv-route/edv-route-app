import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'brand_text_field.dart';

/// Password variant of [BrandTextField] with a show/hide toggle. Stateful only
/// to own the obscure flag; validation and submission are delegated upward.
class PasswordField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const PasswordField({
    super.key,
    this.label = 'Contraseña',
    this.controller,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onFieldSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return BrandTextField(
      label: widget.label,
      controller: widget.controller,
      prefixIcon: const Icon(Icons.lock_outline, size: 20),
      obscureText: _obscured,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      suffixIcon: IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.muted,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
        tooltip: _obscured ? 'Mostrar contraseña' : 'Ocultar contraseña',
      ),
    );
  }
}
