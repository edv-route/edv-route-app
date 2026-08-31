import 'package:flutter/material.dart';

import '../../../../../core/di.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../../shared/validators/person_validators.dart';
import '../../../../../shared/widgets/brand_text_field.dart';
import '../../../../../shared/widgets/gradient_header.dart';
import '../../../../../shared/widgets/operator_phone_field.dart';
import '../../../../../shared/widgets/password_field.dart';
import '../../../../../shared/widgets/registration_fields.dart';
import '../../../../../theme/app_colors.dart';

/// Self-service edit of the passenger's own data. Unlike the affiliate's, the
/// NAMES are editable here: a client has no office-verified identity behind
/// his account, so there is nothing to protect them with. Changing the
/// password requires the current one (backend rule).
///
/// Pops with the updated [Client] so the profile repaints without re-login.
class ClientEditProfileScreen extends StatefulWidget {
  final Client client;

  /// Opens the "Cambiar mi clave" section unfolded (the profile's shortcut).
  final bool openPasswordSection;

  const ClientEditProfileScreen({
    super.key,
    required this.client,
    this.openPasswordSection = false,
  });

  @override
  State<ClientEditProfileScreen> createState() => _ClientEditProfileScreenState();
}

class _ClientEditProfileScreenState extends State<ClientEditProfileScreen> {
  final _repository = Dependencies.instance.clientAuthRepository;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName =
      TextEditingController(text: widget.client.firstName);
  late final TextEditingController _middleName =
      TextEditingController(text: widget.client.middleName ?? '');
  late final TextEditingController _lastName =
      TextEditingController(text: widget.client.lastName);
  late final TextEditingController _secondLastName =
      TextEditingController(text: widget.client.secondLastName ?? '');
  late String _phoneOperator;
  late final TextEditingController _phoneNumber;
  late final TextEditingController _email =
      TextEditingController(text: widget.client.email ?? '');
  late final TextEditingController _address =
      TextEditingController(text: widget.client.address ?? '');
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  late bool _changingPassword = widget.openPasswordSection;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final split = _splitPhone(widget.client.phone);
    _phoneOperator = split.$1;
    _phoneNumber = TextEditingController(text: split.$2);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _secondLastName.dispose();
    _phoneNumber.dispose();
    _email.dispose();
    _address.dispose();
    _currentPassword.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  /// Splits a stored `+58XXXYYYYYYY` back into the operator selector plus the
  /// 7 local digits. Anything that does not fit that shape falls back to the
  /// first operator with an empty number, so a legacy value never blocks the form.
  (String, String) _splitPhone(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 12 && digits.startsWith('58')) {
      final operator = digits.substring(2, 5);
      if (kPhoneOperators.any((o) => o.code == operator)) {
        return (operator, digits.substring(5));
      }
    }
    return (kPhoneOperators.first.code, '');
  }

  String? _validateNewPassword(String? v) {
    if (!_changingPassword) return null;
    return validateNewPassword(v);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final local = _phoneNumber.text.trim();
    setState(() => _saving = true);
    try {
      final updated = await _repository.updateProfile(
        firstName: titleCase(_firstName.text),
        middleName: titleCase(_middleName.text),
        lastName: titleCase(_lastName.text),
        secondLastName: titleCase(_secondLastName.text),
        phone: local.isEmpty ? '' : '+58$_phoneOperator$local',
        email: _email.text.trim(),
        address: _address.text.trim(),
        password: _changingPassword ? _password.text : null,
        currentPassword: _changingPassword ? _currentPassword.text : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo guardar. Intenta de nuevo.');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            height: GradientHeader.kStandardHeight,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 20, 14),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Editar mis datos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  _nameField('Primer nombre', _firstName, required: true, field: 'tu primer nombre'),
                  const SizedBox(height: 14),
                  _nameField('Segundo nombre (opcional)', _middleName,
                      required: false, field: 'tu segundo nombre'),
                  const SizedBox(height: 14),
                  _nameField('Primer apellido', _lastName, required: true, field: 'tu primer apellido'),
                  const SizedBox(height: 14),
                  _nameField('Segundo apellido (opcional)', _secondLastName,
                      required: false, field: 'tu segundo apellido'),
                  const SizedBox(height: 14),
                  OperatorPhoneField(
                    label: 'Teléfono',
                    operator: _phoneOperator,
                    onOperatorChanged: (o) => setState(() => _phoneOperator = o),
                    controller: _phoneNumber,
                    validator: validatePersonPhone,
                  ),
                  const SizedBox(height: 14),
                  BrandTextField(
                    label: 'Correo',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: validatePersonEmail,
                  ),
                  const SizedBox(height: 14),
                  BrandTextField(
                    label: 'Dirección (opcional)',
                    controller: _address,
                    hintText: 'Tu dirección',
                  ),
                  const SizedBox(height: 20),
                  _passwordSection(),
                  const SizedBox(height: 22),
                  // The error sits NEXT TO the button, not at the top: that is
                  // where he is looking when the save fails.
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameField(
    String label,
    TextEditingController controller, {
    required bool required,
    required String field,
  }) {
    return BrandTextField(
      label: label,
      controller: controller,
      textCapitalization: TextCapitalization.words,
      inputFormatters: letterInputFormatters(80),
      validator: (v) => validatePersonName(v, required: required, field: field),
    );
  }

  Widget _passwordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _changingPassword = !_changingPassword),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _changingPassword ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Cambiar mi clave',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_changingPassword) ...[
          const SizedBox(height: 10),
          PasswordField(
            label: 'Clave actual',
            controller: _currentPassword,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                !_changingPassword || (v ?? '').isNotEmpty ? null : 'Escribe tu clave actual.',
          ),
          const SizedBox(height: 14),
          PasswordField(
            label: 'Nueva clave',
            controller: _password,
            textInputAction: TextInputAction.next,
            validator: _validateNewPassword,
          ),
          const SizedBox(height: 14),
          PasswordField(
            label: 'Repite la nueva clave',
            controller: _passwordConfirm,
            validator: (v) => !_changingPassword
                ? null
                : ((v ?? '') != _password.text ? 'Las claves no coinciden.' : null),
          ),
        ],
      ],
    );
  }
}
