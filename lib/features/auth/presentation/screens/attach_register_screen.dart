import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/validators/person_validators.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/brand_text_field.dart';
import '../../../../shared/widgets/operator_phone_field.dart';
import '../../../../shared/widgets/password_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/privacy_check.dart';
import '../../../../theme/app_colors.dart';

/// The SHORT registration (decision by Luis, 2026-09-01), shared by both
/// directions: someone who already has one hat gains the other. He proves it
/// is him with the password he already has, and types only what is HIS in the
/// new role — email, phone and this role's password (same or different, his
/// call). Names, cédula and birth date are the person's: neither asked nor
/// shown (nothing is revealed to whoever only typed a cédula).
class AttachRegisterScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  /// The already-validated cédula from the gate screen, shown locked.
  final String nationalId;

  /// Label of the ownership-proof field ("Tu clave de cliente", …).
  final String currentPasswordLabel;

  /// Runs the attach; throws [ApiException] with the reason on failure.
  final Future<void> Function({
    required String currentPassword,
    required String email,
    required String phone,
    required String password,
  }) submit;

  /// Navigate wherever this role starts once the attach succeeded.
  final void Function(BuildContext context) onSuccess;

  const AttachRegisterScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.nationalId,
    required this.currentPasswordLabel,
    required this.submit,
    required this.onSuccess,
  });

  @override
  State<AttachRegisterScreen> createState() => _AttachRegisterScreenState();
}

class _AttachRegisterScreenState extends State<AttachRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  String _phoneOperator = kPhoneOperators.first.code;
  final _phoneNumber = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _acceptedPrivacy = false;
  bool _privacyError = false;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentPassword.dispose();
    _phoneNumber.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    final formOk = _formKey.currentState?.validate() ?? false;
    final privacyMissing = !_acceptedPrivacy;
    if (privacyMissing) setState(() => _privacyError = true);
    if (!formOk || privacyMissing) return;

    setState(() => _loading = true);
    try {
      await widget.submit(
        currentPassword: _currentPassword.text,
        email: _email.text.trim(),
        phone: '+58$_phoneOperator${_phoneNumber.text.trim()}',
        password: _password.text,
      );
      if (mounted) widget.onSuccess(context);
      return;
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo completar el registro. Intenta de nuevo.');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AuthHeader(showBack: true, title: widget.title, subtitle: widget.subtitle),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The person the system recognized — by cédula only; the
                    // name appears AFTER proving the password, never before.
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardGrey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ya tienes cuenta con la cédula ${widget.nationalId}. '
                              'Solo faltan los datos de este nuevo rol.',
                              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    PasswordField(
                      label: widget.currentPasswordLabel,
                      controller: _currentPassword,
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'Escribe la clave que ya tienes.' : null,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Es la prueba de que esta cuenta es tuya.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    BrandTextField(
                      label: 'Correo para este rol',
                      controller: _email,
                      hintText: 'correo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: validatePersonEmail,
                    ),
                    const SizedBox(height: 14),
                    OperatorPhoneField(
                      label: 'Teléfono para este rol',
                      operator: _phoneOperator,
                      onOperatorChanged: (o) => setState(() => _phoneOperator = o),
                      controller: _phoneNumber,
                      validator: validateRequiredPersonPhone,
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      label: 'Clave para este rol',
                      controller: _password,
                      textInputAction: TextInputAction.next,
                      validator: validateNewPassword,
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      label: 'Repite la clave',
                      controller: _passwordConfirm,
                      validator: (v) => validatePasswordConfirm(v, _password.text),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Solo números, de 6 a 8. Puede ser la misma que ya usas o una distinta.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    PrivacyCheck(
                      value: _acceptedPrivacy,
                      error: _privacyError,
                      onChanged: (v) => setState(() {
                        _acceptedPrivacy = v;
                        if (v) _privacyError = false;
                      }),
                    ),
                    const SizedBox(height: 22),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    PrimaryButton(label: 'Completar registro', loading: _loading, onPressed: _submit),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
