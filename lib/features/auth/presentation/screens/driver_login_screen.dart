import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/password_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
import '../../../home/presentation/screens/driver_root_screen.dart';
import '../controllers/driver_login_controller.dart';
import '../widgets/national_id_field.dart';

/// Driver login. Authenticates by national ID ("cédula") + password against the
/// backend `driver-auth` module. On success it routes to the driver home
/// (which branches by status); errors surface next to the button.
class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  String _docType = 'V';
  late final DriverLoginController _controller =
      DriverLoginController(Dependencies.instance.authRepository);

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final nationalId = '$_docType-${_idController.text.trim()}';
    final driver = await _controller.login(nationalId, _passwordController.text);
    if (driver != null && mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DriverRootScreen(driver: driver)),
      );
    }
  }

  void _showSoon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateId(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu cédula.';
    if (v.length < 5 || v.length > 9) return 'La cédula no es válida.';
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
            title: 'Ingresar como conductor',
            subtitle: 'o llena la solicitud para registrarte',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NationalIdField(
                      type: _docType,
                      onTypeChanged: (t) => setState(() => _docType = t),
                      controller: _idController,
                      validator: _validateId,
                    ),
                    const SizedBox(height: 18),
                    PasswordField(
                      controller: _passwordController,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () =>
                            _showSoon('Recuperación de clave: próximamente.'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Olvidé mi contraseña'),
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
                            label: 'Iniciar sesión',
                            loading: _controller.loading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        const Text(
                          '¿Aún no eres conductor?',
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRoutes.driverRegister),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text('Registrarme'),
                        ),
                      ],
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
