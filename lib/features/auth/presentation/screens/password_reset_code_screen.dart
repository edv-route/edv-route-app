import 'package:flutter/material.dart';

import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/code_input_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
import '../controllers/password_reset_controller.dart';
import '../widgets/reset_error_line.dart';
import 'password_reset_new_screen.dart';

/// Step 2: the six digits that came by email. Shared by both recovery
/// channels; the channel params ride through to the next screens untouched.
///
/// The controller arrives from the previous screen rather than being built here
/// — it already holds whose account this is, and rebuilding it would lose that.
class PasswordResetCodeScreen extends StatefulWidget {
  const PasswordResetCodeScreen({
    super.key,
    required this.controller,
    this.loginRoute,
    this.intro,
    this.doneMessage,
  });

  final PasswordResetController controller;

  /// Channel overrides forwarded to [PasswordResetNewScreen]; null keeps its
  /// driver defaults.
  final String? loginRoute;
  final String? intro;
  final String? doneMessage;

  @override
  State<PasswordResetCodeScreen> createState() => _PasswordResetCodeScreenState();
}

class _PasswordResetCodeScreenState extends State<PasswordResetCodeScreen> {
  final _codeKey = GlobalKey<CodeInputFieldState>();
  String _code = '';
  bool _wrong = false;

  Future<void> _submit([String? code]) async {
    final value = code ?? _code;
    if (value.length != 6 || widget.controller.loading) return;

    final ok = await widget.controller.verifyCode(value);
    if (!mounted) return;
    if (!ok) {
      // Clear the boxes on a wrong code: he has to retype it anyway, and
      // leaving six wrong digits sitting there means deleting them one by one
      // before he can try again.
      setState(() => _wrong = true);
      _codeKey.currentState?.clear();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PasswordResetNewScreen(
          controller: widget.controller,
          loginRoute: widget.loginRoute ?? AppRoutes.driverLogin,
          intro: widget.intro,
          doneMessage: widget.doneMessage,
        ),
      ),
    );
  }

  Future<void> _resend() async {
    setState(() => _wrong = false);
    _codeKey.currentState?.clear();
    await widget.controller.resendCode();
  }

  String _mmss(Duration d) {
    final s = d.inSeconds.clamp(0, 3599);
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            showBack: true,
            title: 'Ingresa el código',
            subtitle: 'Paso 2 de 3 · Revisa tu correo',
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final c = widget.controller;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Escribe el código de 6 dígitos que enviamos a',
                        style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.ink),
                      ),
                      Text(
                        c.email,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 28),
                      CodeInputField(
                        key: _codeKey,
                        hasError: _wrong,
                        enabled: !c.loading && !c.expired,
                        onChanged: (v) => setState(() {
                          _code = v;
                          // The red boxes belong to the code he already sent,
                          // not to the one he is typing now.
                          if (_wrong && v.isNotEmpty) _wrong = false;
                        }),
                        onCompleted: _submit,
                      ),
                      const SizedBox(height: 14),
                      if (c.error != null) ...[
                        ResetErrorLine(message: c.error!, center: true),
                        const SizedBox(height: 14),
                      ],
                      _Countdown(remaining: c.remaining, label: _mmss(c.remaining)),
                      const SizedBox(height: 22),
                      PrimaryButton(
                        label: 'Verificar código',
                        loading: c.loading,
                        // Enabled only with six digits: a half-typed code would
                        // spend one of his three tries for nothing.
                        onPressed: _code.length == 6 && !c.expired ? _submit : null,
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          const Text(
                            '¿No te llegó el correo?',
                            style: TextStyle(fontSize: 13, color: AppColors.muted),
                          ),
                          TextButton(
                            onPressed: c.untilResend > Duration.zero || c.loading ? null : _resend,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              disabledForegroundColor: AppColors.fieldBorder,
                            ),
                            child: Text(
                              c.untilResend > Duration.zero
                                  ? 'Reenviar código en ${_mmss(c.untilResend)}'
                                  : 'Reenviar código',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// How long the code is still good for. Turns into a plain instruction once it
/// runs out — a countdown reading 0:00 tells him nothing about what to do next.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining, required this.label});

  final Duration remaining;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (remaining <= Duration.zero) {
      return const Text(
        'El código venció. Pide uno nuevo.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.schedule, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        const Text('El código vence en ', style: TextStyle(fontSize: 13, color: AppColors.muted)),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
