import 'package:flutter/material.dart';

import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/password_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
import '../controllers/password_reset_controller.dart';
import '../widgets/reset_error_line.dart';
import 'password_reset_done_screen.dart';

/// Step 3: the new password. Shared by both recovery channels; the defaults
/// speak driver, and the client flow passes its own routes and copy.
///
/// The rules match what the API enforces (min 6, digits allowed — the PIN-like
/// policy of 2026-07-16). They are shown as a live checklist rather than as an
/// error after submitting: someone typing a 4-digit PIN should see why the
/// button is dead, not press it and get told off.
class PasswordResetNewScreen extends StatefulWidget {
  const PasswordResetNewScreen({
    super.key,
    required this.controller,
    this.loginRoute = AppRoutes.driverLogin,
    String? intro,
    this.doneMessage,
  }) : intro = intro ?? 'Elige una clave nueva. La usarás junto a tu cédula para entrar.';

  final PasswordResetController controller;

  /// The named login route this recovery started from — where the done screen
  /// lands the user back.
  final String loginRoute;

  /// The sentence above the fields: how this channel signs in.
  final String intro;

  /// Override for the done screen's body; null keeps its driver default.
  final String? doneMessage;

  @override
  State<PasswordResetNewScreen> createState() => _PasswordResetNewScreenState();
}

class _PasswordResetNewScreenState extends State<PasswordResetNewScreen> {
  final _password = TextEditingController();
  final _repeat = TextEditingController();

  static const _minLength = 6;

  @override
  void initState() {
    super.initState();
    _password.addListener(_refresh);
    _repeat.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _password.removeListener(_refresh);
    _repeat.removeListener(_refresh);
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  bool get _longEnough => _password.text.trim().length >= _minLength;
  bool get _matches => _password.text.isNotEmpty && _password.text == _repeat.text;
  bool get _valid => _longEnough && _matches;

  Future<void> _submit() async {
    if (!_valid || widget.controller.loading) return;
    final ok = await widget.controller.confirm(_password.text.trim());
    if (!ok || !mounted) return;
    // Replaces the stack: the recovery is over and there is nothing behind this
    // worth going back to — least of all a spent code.
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PasswordResetDoneScreen(
          loginRoute: widget.loginRoute,
          message: widget.doneMessage,
        ),
      ),
      ModalRoute.withName(widget.loginRoute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            showBack: true,
            title: 'Crea tu nueva clave',
            subtitle: 'Paso 3 de 3 · Último paso',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.intro,
                    style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.ink),
                  ),
                  const SizedBox(height: 24),
                  PasswordField(
                    label: 'Nueva clave',
                    controller: _password,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 18),
                  PasswordField(
                    label: 'Repetir nueva clave',
                    controller: _repeat,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        _Rule(met: _longEnough, label: 'Al menos $_minLength caracteres'),
                        const SizedBox(height: 10),
                        _Rule(met: _matches, label: 'Las dos claves coinciden'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.controller.error != null) ...[
                          ResetErrorLine(message: widget.controller.error!),
                          const SizedBox(height: 10),
                        ],
                        PrimaryButton(
                          label: 'Guardar clave',
                          loading: widget.controller.loading,
                          onPressed: _valid ? _submit : null,
                        ),
                      ],
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

/// One requirement, ticked live. Green is the same "Aprobado" green the
/// checklist already uses, so a tick means the same thing across the app.
class _Rule extends StatelessWidget {
  const _Rule({required this.met, required this.label});

  final bool met;
  final String label;

  static const _okFg = Color(0xFF166534);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check : Icons.circle_outlined,
          size: 18,
          color: met ? _okFg : AppColors.fieldBorder,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
              color: met ? _okFg : AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}
