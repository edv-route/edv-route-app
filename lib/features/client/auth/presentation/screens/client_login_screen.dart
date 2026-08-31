import 'package:flutter/material.dart';

import '../../../../../core/di.dart';
import '../../../../../routing/app_routes.dart';
import '../../../../../shared/widgets/auth_header.dart';
import '../../../../../shared/widgets/brand_text_field.dart';
import '../../../../../shared/widgets/password_field.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../../theme/app_colors.dart';
import '../../../home/presentation/screens/client_shell.dart';
import '../controllers/client_login_controller.dart';

/// Passenger login. ONE identifier field — email or phone, whichever he
/// remembers (decision by Luis, 2026-08-31) — because unlike the affiliate,
/// a passenger has no cédula on file. Errors surface next to the button.
class ClientLoginScreen extends StatefulWidget {
  const ClientLoginScreen({super.key});

  @override
  State<ClientLoginScreen> createState() => _ClientLoginScreenState();
}

class _ClientLoginScreenState extends State<ClientLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  late final ClientLoginController _controller =
      ClientLoginController(Dependencies.instance.clientAuthRepository);

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final client = await _controller.login(
      _identifierController.text,
      _passwordController.text,
    );
    if (client != null && mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ClientShell(client: client)),
      );
    }
  }

  String? _validateIdentifier(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Ingresa tu correo o tu teléfono.';
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Ingresa tu clave.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            showBack: true,
            title: 'Entrar como pasajero',
            highlight: 'pasajero',
            subtitle: 'o crea tu cuenta en un minuto',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BrandTextField(
                      label: 'Correo o teléfono',
                      controller: _identifierController,
                      hintText: 'tucorreo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.alternate_email, size: 20),
                      validator: _validateIdentifier,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Puedes entrar con tu correo o con tu número de teléfono.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      label: 'Clave',
                      controller: _passwordController,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.clientPasswordReset),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Olvidé mi clave'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Button + error area rebuild together with the controller.
                    ListenableBuilder(
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
                            label: 'Entrar',
                            loading: _controller.loading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '¿No tienes cuenta?',
                            style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.clientRegister),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Crear mi cuenta'),
                    ),
                    const Divider(height: 28),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Cambiar de modo'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary900,
                        ),
                      ),
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
