import 'package:flutter/material.dart';

import '../../../../core/utils/date_format.dart';
import 'package:flutter/services.dart';

import '../../../../core/di.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/brand_text_field.dart';
import '../../../../shared/widgets/password_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../../data/models/register_request.dart';
import '../controllers/driver_register_controller.dart';
import '../../../../shared/widgets/national_id_field.dart';
import '../../../../shared/widgets/operator_phone_field.dart';
import '../../../../shared/widgets/privacy_check.dart';
import '../../../../shared/widgets/registration_fields.dart';
import '../../../../shared/validators/person_validators.dart';
import '../../../enrollment/presentation/screens/checklist_hub_screen.dart';

/// Driver self-registration — STEP 1 (solicitudes-app): personal data + privacy
/// consent. Submitting creates an `applicant` and continues to the checklist,
/// where the applicant uploads documents/vehicle and (after approval) pays. Field
/// rules, order and formats mirror the admin panel so the client rejects bad input
/// before the API. (The old 4-step wizard is gone: docs/vehicle/payment moved to
/// the checklist and the /me/* endpoints.)
class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  late final DriverRegisterController _controller =
      DriverRegisterController(Dependencies.instance.enrollmentRepository);

  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _secondLastName = TextEditingController();
  DateTime? _birthDate;
  bool _birthDateError = false;
  String _docType = 'V';
  final _idDigits = TextEditingController();
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
    _idDigits.dispose();
    _phoneNumber.dispose();
    _email.dispose();
    _address.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  // --- validators: the person rules live in shared/validators (mirroring the
  // backend), shared with the client registration; only the national id is
  // affiliate-specific and stays here.
  String? _validateId(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Ingresa tu documento.';
    if (t.length < 5 || t.length > 9) return 'El documento debe tener entre 5 y 9 dígitos.';
    return null;
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

    final driver = await _controller.register(_buildRequest());
    if (driver != null && mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChecklistHubScreen()),
      );
    }
  }

  RegisterRequest _buildRequest() => RegisterRequest(
        firstName: titleCase(_firstName.text),
        middleName: titleCase(_middleName.text),
        lastName: titleCase(_lastName.text),
        secondLastName: titleCase(_secondLastName.text),
        birthDate: _birthDate == null ? null : formatApiDate(_birthDate!),
        phone: _composePersonPhone(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        nationalId: '$_docType-${_idDigits.text.trim()}',
        password: _password.text,
        acceptedPrivacy: _acceptedPrivacy,
      );

  /// Composes the phone from the operator selector + a 7-digit local number into
  /// E.164 (+58 + operator + 7 digits). Returns null when blank.
  String? _composePersonPhone() {
    final local = _phoneNumber.text.trim();
    if (local.isEmpty || local.length != 7) return null;
    return '+58$_phoneOperator$local';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            showBack: true,
            title: 'Crea tu solicitud',
            subtitle: 'Empieza con tus datos personales',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BrandTextField(
                      label: 'Primer nombre',
                      controller: _firstName,
                      hintText: 'Tu primer nombre',
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: letterInputFormatters(80),
                      validator: (v) => validatePersonName(v, required: true, field: 'tu primer nombre'),
                    ),
                    const SizedBox(height: 14),
                    BrandTextField(
                      label: 'Segundo nombre (opcional)',
                      controller: _middleName,
                      hintText: 'Tu segundo nombre',
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: letterInputFormatters(80),
                      validator: (v) => validatePersonName(v, required: false, field: 'tu segundo nombre'),
                    ),
                    const SizedBox(height: 14),
                    BrandTextField(
                      label: 'Primer apellido',
                      controller: _lastName,
                      hintText: 'Tu primer apellido',
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: letterInputFormatters(80),
                      validator: (v) => validatePersonName(v, required: true, field: 'tu primer apellido'),
                    ),
                    const SizedBox(height: 14),
                    BrandTextField(
                      label: 'Segundo apellido (opcional)',
                      controller: _secondLastName,
                      hintText: 'Tu segundo apellido',
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: letterInputFormatters(80),
                      validator: (v) => validatePersonName(v, required: false, field: 'tu segundo apellido'),
                    ),
                    const SizedBox(height: 14),
                    DateField(
                      label: 'Fecha de nacimiento (mayor de 18)',
                      value: _birthDate,
                      onTap: _pickBirthDate,
                      errorText: _birthDateError ? 'Selecciona tu fecha de nacimiento.' : null,
                    ),
                    const SizedBox(height: 14),
                    NationalIdField(
                      label: 'Documento de identidad',
                      hintText: '12345678',
                      locked: true,
                      type: _docType,
                      onTypeChanged: (t) => setState(() => _docType = t),
                      controller: _idDigits,
                      validator: _validateId,
                    ),
                    const SizedBox(height: 14),
                    OperatorPhoneField(
                      label: 'Teléfono (opcional)',
                      operator: _phoneOperator,
                      onOperatorChanged: (o) => setState(() => _phoneOperator = o),
                      controller: _phoneNumber,
                      validator: validatePersonPhone,
                    ),
                    const SizedBox(height: 14),
                    BrandTextField(
                      label: 'Correo',
                      controller: _email,
                      hintText: 'correo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: validatePersonEmail,
                    ),
                    const SizedBox(height: 14),
                    BrandTextField(
                      label: 'Dirección (opcional)',
                      controller: _address,
                      hintText: 'Tu dirección',
                      inputFormatters: [LengthLimitingTextInputFormatter(500)],
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
                      'Tu usuario será tu número de documento. Con esta clave entrarás a la '
                      'app (mínimo 6 caracteres; puede ser solo números).',
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
              label: 'Crear solicitud',
              loading: _controller.submitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
