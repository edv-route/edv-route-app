import 'package:flutter/material.dart';

import '../../../../../core/di.dart';
import '../../../../../routing/app_routes.dart';
import '../../../../../shared/validators/person_validators.dart';
import '../../../../../shared/widgets/auth_header.dart';
import '../../../../../shared/widgets/brand_text_field.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../auth/presentation/controllers/password_reset_controller.dart';
import '../../../../auth/presentation/screens/password_reset_code_screen.dart';
import '../../../../auth/presentation/widgets/code_sent_dialog.dart';
import '../../../../auth/presentation/widgets/reset_error_line.dart';
import '../../../../../domain/repositories/password_reset_repository.dart';

/// Step 1 of the passenger's "olvidé mi clave": his email, alone.
///
/// Unlike the driver (who proves himself with cédula + email), a passenger has
/// no cédula on file — the email is both his identifier and where the code
/// lands. Steps 2 and 3 are the SAME screens the driver walks, pointed at the
/// client endpoints by the repository and at the client login by the params.
class ClientPasswordResetScreen extends StatefulWidget {
  const ClientPasswordResetScreen({super.key});

  @override
  State<ClientPasswordResetScreen> createState() => _ClientPasswordResetScreenState();
}

class _ClientPasswordResetScreenState extends State<ClientPasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  /// The controller is created here and OWNED by this screen even though the
  /// next two use it: it holds the identity and the reset token, and that is
  /// one answer the whole flow shares.
  late final PasswordResetController _controller =
      PasswordResetController(Dependencies.instance.clientPasswordResetRepository);

  @override
  void dispose() {
    _emailController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await _controller
        .requestCode(ResetIdentity(email: _emailController.text.trim()));
    if (!ok || !mounted) return;

    // The modal is the moment the passenger is told to leave the app and go
    // read his mail — same reasoning as the driver's flow.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CodeSentDialog(email: _controller.email),
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PasswordResetCodeScreen(
          controller: _controller,
          loginRoute: AppRoutes.clientLogin,
          intro: 'Elige una clave nueva. La usarás junto a tu correo (o tu teléfono) para entrar.',
          doneMessage:
              'Ya puedes entrar con tu correo (o tu teléfono) y tu clave nueva. Te enviamos un correo confirmando el cambio.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            showBack: true,
            title: 'Recuperar mi clave',
            subtitle: 'Paso 1 de 3 · Tu correo',
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
                      'Escribe el correo con el que te registraste. Te enviaremos un código para crear una clave nueva.',
                      style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.ink),
                    ),
                    const SizedBox(height: 24),
                    BrandTextField(
                      label: 'Correo electrónico',
                      controller: _emailController,
                      hintText: 'correo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: validatePersonEmail,
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
                    // already learned. Whoever lost access to the mailbox
                    // itself has to be told where recovery IS possible.
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
                            '¿Ya no tienes acceso a ese correo? Comunícate con la oficina para recuperar tu cuenta.',
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
