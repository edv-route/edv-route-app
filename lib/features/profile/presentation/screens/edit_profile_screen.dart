import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/gradient_header.dart';
import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/driver.dart';
import '../../../../shared/widgets/operator_phone_field.dart';

/// Self-service edit of the driver's own data. The form deliberately offers ONLY
/// what the backend accepts on PATCH /me — phone, email, address and password:
/// names and national id are the identity an admin verified against approved
/// documents, so they are shown read-only with a note on how to change them.
///
/// Pops with the updated [Driver] so the profile repaints without re-logging in.
class EditProfileScreen extends StatefulWidget {
  final Driver driver;

  const EditProfileScreen({super.key, required this.driver});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _repository = Dependencies.instance.accountRepository;
  final _formKey = GlobalKey<FormState>();

  late String _phoneOperator;
  late final TextEditingController _phoneNumber;
  late final TextEditingController _email;
  final _address = TextEditingController();
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  bool _changingPassword = false;
  bool _loadingAddress = true;
  bool _saving = false;
  String? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    final split = _splitPhone(widget.driver.phone);
    _phoneOperator = split.$1;
    _phoneNumber = TextEditingController(text: split.$2);
    _email = TextEditingController(text: widget.driver.email ?? '');
    _loadAddress();
  }

  @override
  void dispose() {
    _phoneNumber.dispose();
    _email.dispose();
    _address.dispose();
    _currentPassword.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  /// Splits a stored `+58XXXYYYYYYY` back into the operator selector plus the 7
  /// local digits. Anything that does not fit that shape falls back to the first
  /// operator with an empty number, so a legacy value never blocks the form.
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

  Future<void> _loadAddress() async {
    try {
      final address = await _repository.loadAddress();
      if (!mounted) return;
      _address.text = address ?? '';
    } catch (_) {
      // The address is only a prefill: an empty field beats a blocked form.
      // Leaving it untouched sends nothing and keeps whatever is stored.
    }
    if (mounted) setState(() => _loadingAddress = false);
  }

  String? _validatePhone(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    if (t.length != 7) return 'El teléfono debe tener 7 dígitos (ej. 1234567).';
    return null;
  }

  String? _validateEmail(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    if (!_emailRegex.hasMatch(t)) return 'Correo inválido.';
    return null;
  }

  String? _validateNewPassword(String? v) {
    if (!_changingPassword) return null;
    final t = v ?? '';
    if (t.isEmpty) return 'Escribe tu nueva clave.';
    if (t.length < 6 || t.length > 72) return 'Entre 6 y 72 caracteres.';
    return null;
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final local = _phoneNumber.text.trim();
    setState(() => _saving = true);
    try {
      final updated = await _repository.updateOwnProfile(
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
                  _identityCard(),
                  const SizedBox(height: 18),
                  OperatorPhoneField(
                    label: 'Teléfono',
                    operator: _phoneOperator,
                    onOperatorChanged: (o) => setState(() => _phoneOperator = o),
                    controller: _phoneNumber,
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    label: 'Correo',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    label: 'Dirección',
                    controller: _address,
                    maxLines: 2,
                    hint: _loadingAddress ? 'Cargando…' : null,
                  ),
                  const SizedBox(height: 20),
                  _passwordSection(),
                  const SizedBox(height: 22),
                  // The error sits NEXT TO the button, not at the top: that is
                  // where the driver is looking when the save fails.
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

  /// Name and national id are read-only here on purpose (see the class doc).
  Widget _identityCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardGrey.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driver.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.driver.nationalId ?? '—',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tu nombre y tu cédula no se editan aquí: son los datos que la oficina verificó con tus documentos. Si hay un error, escríbenos.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
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
          _field(
            label: 'Clave actual',
            controller: _currentPassword,
            obscure: true,
            validator: (v) => (v ?? '').isEmpty ? 'Escribe tu clave actual.' : null,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Nueva clave',
            controller: _password,
            obscure: true,
            validator: _validateNewPassword,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Repite la nueva clave',
            controller: _passwordConfirm,
            obscure: true,
            validator: (v) => (v ?? '') != _password.text ? 'Las claves no coinciden.' : null,
          ),
        ],
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscure = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
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
        TextFormField(
          controller: controller,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
