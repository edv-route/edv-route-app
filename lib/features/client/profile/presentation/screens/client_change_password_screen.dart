import 'package:flutter/material.dart';

import '../../../../../core/di.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../shared/validators/person_validators.dart';
import '../../../../../shared/widgets/gradient_header.dart';
import '../../../../../shared/widgets/password_field.dart';
import '../../../../../theme/app_colors.dart';

/// Changing the passenger's password, and NOTHING else (decision by Luis,
/// 2026-08-31: editing the profile and changing the key are separate errands).
/// The current password is required — a stolen session must not be enough to
/// lock the owner out of his own account (backend rule).
///
/// Pops with `true` on success so the profile can confirm it out loud.
class ClientChangePasswordScreen extends StatefulWidget {
  const ClientChangePasswordScreen({super.key});

  @override
  State<ClientChangePasswordScreen> createState() => _ClientChangePasswordScreenState();
}

class _ClientChangePasswordScreenState extends State<ClientChangePasswordScreen> {
  final _repository = Dependencies.instance.clientAuthRepository;
  final _formKey = GlobalKey<FormState>();

  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentPassword.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await _repository.updateProfile(
        password: _password.text,
        currentPassword: _currentPassword.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo cambiar tu clave. Intenta de nuevo.');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Same header anatomy as the edit screen (logo row + title), so the
          // two profile sub-screens read as one family.
          GradientHeader(
            height: GradientHeader.kStandardHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Image(
                        image: AssetImage('assets/images/edv_logo_gold.png'),
                        height: 26,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'Cambiar mi clave',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  const Text(
                    'Escribe tu clave actual y elige una nueva. La usarás junto a tu correo (o tu teléfono) para entrar.',
                    style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.ink),
                  ),
                  const SizedBox(height: 20),
                  PasswordField(
                    label: 'Clave actual',
                    controller: _currentPassword,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v ?? '').isEmpty ? 'Escribe tu clave actual.' : null,
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    label: 'Nueva clave',
                    controller: _password,
                    textInputAction: TextInputAction.next,
                    validator: validateNewPassword,
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    label: 'Repite la nueva clave',
                    controller: _passwordConfirm,
                    onFieldSubmitted: (_) => _save(),
                    validator: (v) =>
                        (v ?? '') != _password.text ? 'Las claves no coinciden.' : null,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Solo números, de 6 a 8.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
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
                          : const Text('Guardar clave'),
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
}
