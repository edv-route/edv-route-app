import 'package:flutter/material.dart';

import '../../../../../core/di.dart';
import '../../../../../core/utils/date_format.dart';
import '../../../../../data/models/client_register_request.dart';
import '../../../../../shared/validators/person_validators.dart';
import '../../../../../shared/widgets/auth_header.dart';
import '../../../../../shared/widgets/brand_text_field.dart';
import '../../../../../shared/widgets/operator_phone_field.dart';
import '../../../../../shared/widgets/password_field.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../shared/widgets/privacy_check.dart';
import '../../../../../shared/widgets/registration_fields.dart';
import '../../../../../theme/app_colors.dart';
import '../../../home/presentation/screens/client_shell.dart';
import '../controllers/client_register_controller.dart';

/// Passenger self-registration: the SAME fields as the affiliate's, with the
/// same shared validators (decision by Luis, 2026-08-31 — it replaced the
/// earlier "solo datos básicos" cut). Cédula, birth date and phone are
/// mandatory; only middle name, second last name and address are optional.
/// Registering signs him in directly: no approval step.
class ClientRegisterScreen extends StatefulWidget {
  /// Already validated by the cédula gate (step 0): shown locked here.
  final String nationalId;

  const ClientRegisterScreen({super.key, required this.nationalId});

  @override
  State<ClientRegisterScreen> createState() => _ClientRegisterScreenState();
}

class _ClientRegisterScreenState extends State<ClientRegisterScreen> {
  late final ClientRegisterController _controller =
      ClientRegisterController(Dependencies.instance.clientAuthRepository);

  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _secondLastName = TextEditingController();
  DateTime? _birthDate;
  bool _birthDateError = false;
  String _phoneOperator = kPhoneOperators.first.code;
  final _phoneNumber = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _acceptedPrivacy = false;
  bool _privacyError = false;

  @override
  void dispose() {
    _controller.dispose();
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _secondLastName.dispose();
    _phoneNumber.dispose();
    _email.dispose();
    _address.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final maxBirth = DateTime(now.year - 18, now.month, now.day);
    final initial = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(maxBirth) ? maxBirth : initial,
      firstDate: DateTime(1920),
      lastDate: maxBirth,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateError = false;
      });
    }
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final birthMissing = _birthDate == null;
    final privacyMissing = !_acceptedPrivacy;
    if (birthMissing || privacyMissing) {
      setState(() {
        _birthDateError = birthMissing;
        _privacyError = privacyMissing;
      });
    }
    if (!formOk || birthMissing || privacyMissing) return;

    final client = await _controller.register(_buildRequest());
    if (client != null && mounted) {
      // The register response already carries the session: straight to the app.
      await Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => ClientShell(client: client)),
        (route) => route.isFirst,
      );
    }
  }

  ClientRegisterRequest _buildRequest() => ClientRegisterRequest(
        firstName: titleCase(_firstName.text),
        middleName: titleCase(_middleName.text),
        lastName: titleCase(_lastName.text),
        secondLastName: titleCase(_secondLastName.text),
        birthDate: formatApiDate(_birthDate!),
        nationalId: widget.nationalId,
        phone: '+58$_phoneOperator${_phoneNumber.text.trim()}',
        email: _email.text.trim(),
        address: _address.text.trim(),
        password: _password.text,
        acceptedPrivacy: _acceptedPrivacy,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            showBack: true,
            title: 'Crear mi cuenta',
            subtitle: 'Tus datos personales',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _nameField(
                      label: 'Primer nombre',
                      controller: _firstName,
                      hint: 'Tu primer nombre',
                      required: true,
                      field: 'tu primer nombre',
                    ),
                    const SizedBox(height: 14),
                    _nameField(
                      label: 'Segundo nombre (opcional)',
                      controller: _middleName,
                      hint: 'Tu segundo nombre',
                      required: false,
                      field: 'tu segundo nombre',
                    ),
                    const SizedBox(height: 14),
                    _nameField(
                      label: 'Primer apellido',
                      controller: _lastName,
                      hint: 'Tu primer apellido',
                      required: true,
                      field: 'tu primer apellido',
                    ),
                    const SizedBox(height: 14),
                    _nameField(
                      label: 'Segundo apellido (opcional)',
                      controller: _secondLastName,
                      hint: 'Tu segundo apellido',
                      required: false,
                      field: 'tu segundo apellido',
                    ),
                    const SizedBox(height: 14),
                    DateField(
                      label: 'Fecha de nacimiento',
                      value: _birthDate,
                      onTap: _pickBirthDate,
                      errorText: _birthDateError ? 'Selecciona tu fecha de nacimiento.' : null,
                    ),
                    const SizedBox(height: 14),
                    // The cédula was validated at the gate (step 0): shown
                    // locked so the form and the check can never disagree.
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
                          Text(
                            'Cédula: ${widget.nationalId}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    OperatorPhoneField(
                      label: 'Teléfono',
                      operator: _phoneOperator,
                      onOperatorChanged: (o) => setState(() => _phoneOperator = o),
                      controller: _phoneNumber,
                      validator: validateRequiredPersonPhone,
                    ),
                    const SizedBox(height: 14),
                    BrandTextField(
                      label: 'Correo',
                      controller: _email,
                      hintText: 'correo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: validatePersonEmail,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Es por donde recuperas tu clave si la olvidas.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    BrandTextField(
                      label: 'Dirección (opcional)',
                      controller: _address,
                      hintText: 'Tu dirección',
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      label: 'Crea tu clave',
                      controller: _password,
                      textInputAction: TextInputAction.next,
                      validator: validateNewPassword,
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      label: 'Repite tu clave',
                      controller: _passwordConfirm,
                      validator: (v) => validatePasswordConfirm(v, _password.text),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Con tu correo (o tu teléfono) y esta clave entrarás a la app '
                      '(solo números, de 6 a 8).',
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
                  ],
                ),
              ),
            ),
          ),
          _buildSubmitBar(),
        ],
      ),
    );
  }

  Widget _nameField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool required,
    required String field,
  }) {
    return BrandTextField(
      label: label,
      controller: controller,
      hintText: hint,
      textCapitalization: TextCapitalization.words,
      inputFormatters: letterInputFormatters(80),
      validator: (v) => validatePersonName(v, required: required, field: field),
    );
  }

  Widget _buildSubmitBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_controller.error != null) ...[
              Text(
                _controller.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
            ],
            PrimaryButton(
              label: 'Crear mi cuenta',
              loading: _controller.submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
