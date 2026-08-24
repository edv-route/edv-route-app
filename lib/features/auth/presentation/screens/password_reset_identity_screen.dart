import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/brand_text_field.dart';
import '../../../../shared/widgets/national_id_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../widgets/reset_error_line.dart';
import '../../../../theme/app_colors.dart';
import '../controllers/password_reset_controller.dart';
import 'password_reset_code_screen.dart';

/// Step 1 of "olvidé mi clave": prove who you are with TWO facts.
///
/// The pair is the whole security of the flow — cédula alone is public enough
/// (it is on every document he hands over) and an email alone says nothing
/// about which driver it belongs to.
class PasswordResetIdentityScreen extends StatefulWidget {
  const PasswordResetIdentityScreen({super.key});

  @override
  State<PasswordResetIdentityScreen> createState() => _PasswordResetIdentityScreenState();
}

class _PasswordResetIdentityScreenState extends State<PasswordResetIdentityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  String _docType = 'V';

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// The controller is created here and OWNED by this screen even though the
  /// next two use it: it holds the cédula, the email and the reset token, and
  /// that is one answer the whole flow shares.
  late final PasswordResetController _controller =
      PasswordResetController(Dependencies.instance.passwordResetRepository);

  @override
  void dispose() {
    _idController.dispose();
    _emailController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await _controller.requestCode(
      nationalId: '$_docType-${_idController.text.trim()}',
      email: _emailController.text.trim(),
    );
    if (!ok || !mounted) return;

    // The modal is not decoration: it is the moment the driver is told to leave
    // the app and go read his mail. Skipping straight to the code boxes leaves
    // him staring at six empty squares wondering where the code comes from.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CodeSentDialog(email: _controller.email),
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PasswordResetCodeScreen(controller: _controller)),
    );
  }

  String? _validateId(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu cédula.';
    if (v.length < 5 || v.length > 9) return 'La cédula no es válida.';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo electrónico.';
    if (!_emailRegex.hasMatch(v)) return 'Correo inválido.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            showBack: true,
            title: 'Recuperar mi clave',
            subtitle: 'Paso 1 de 3 · Verifica tu identidad',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ingresa tu cédula y el correo que registraste. Deben coincidir con los datos de tu cuenta.',
                      style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.ink),
                    ),
                    const SizedBox(height: 24),
                    NationalIdField(
                      type: _docType,
                      onTypeChanged: (t) => setState(() => _docType = t),
                      controller: _idController,
                      validator: _validateId,
                    ),
                    const SizedBox(height: 18),
                    BrandTextField(
                      label: 'Correo electrónico',
                      controller: _emailController,
                      hintText: 'correo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      prefixIcon: const Icon(Icons.mail_outline, size: 20),
                    ),
                    const SizedBox(height: 28),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_controller.error != null) ...[
                            ResetErrorLine(message: _controller.error!),
                            const SizedBox(height: 10),
                          ],
                          PrimaryButton(
                            label: 'Continuar',
                            loading: _controller.loading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 44),
                    // A door with no way out is a bug — the lesson this project
                    // already learned three times. A driver with no email on
                    // file cannot recover here, and has to be told where he can.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.info_outline, size: 18, color: AppColors.muted),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '¿No registraste un correo? Comunícate con la oficina para recuperar tu clave.',
                            style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
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

/// Confirms the code left, and to WHICH address — the driver just typed it, so
/// showing it in full lets him catch his own typo before waiting on mail that
/// went to the wrong place.
class _CodeSentDialog extends StatelessWidget {
  const _CodeSentDialog({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_outlined, size: 30, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            const Text(
              'Validación exitosa',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            const Text(
              'Enviamos un código de 6 dígitos a',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
            ),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revisa tu bandeja de entrada. El código vence en 10 minutos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Entendido',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
