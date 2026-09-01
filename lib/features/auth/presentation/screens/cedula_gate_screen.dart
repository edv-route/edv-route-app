import 'package:flutter/material.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/validators/person_validators.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/national_id_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';

/// Step 0 of BOTH registrations (decision by Luis, 2026-09-01): the cédula
/// travels first, and the answer picks the road — full form for a new person,
/// short form for someone who already has the other role, or "go log in" for
/// someone who already has THIS one. Shared by the driver and the client
/// flows: each passes its own texts, its check call and its destinations.
class CedulaGateScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  /// Asks the backend which form this cédula deserves: `new` | `attachable` | `exists`.
  final Future<String> Function(String nationalId) check;

  /// Where each answer goes. `exists` stays here, showing [existsMessage].
  final void Function(BuildContext context, String nationalId) onNew;
  final void Function(BuildContext context, String nationalId) onAttachable;
  final String existsMessage;

  const CedulaGateScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.check,
    required this.onNew,
    required this.onAttachable,
    required this.existsMessage,
  });

  @override
  State<CedulaGateScreen> createState() => _CedulaGateScreenState();
}

class _CedulaGateScreenState extends State<CedulaGateScreen> {
  final _formKey = GlobalKey<FormState>();
  String _docType = 'V';
  final _digits = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _exists = false;

  @override
  void dispose() {
    _digits.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _exists = false;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final nationalId = '$_docType-${_digits.text.trim()}';
    setState(() => _loading = true);
    try {
      final status = await widget.check(nationalId);
      if (!mounted) return;
      setState(() => _loading = false);
      if (status == 'exists') {
        setState(() => _exists = true);
      } else if (status == 'attachable') {
        widget.onAttachable(context, nationalId);
      } else {
        widget.onNew(context, nationalId);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No se pudo comprobar tu cédula. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AuthHeader(showBack: true, title: widget.title, subtitle: widget.subtitle),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Escribe tu cédula. Si ya tienes una cuenta con nosotros, te ahorramos el resto del formulario.',
                      style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.ink),
                    ),
                    const SizedBox(height: 24),
                    NationalIdField(
                      type: _docType,
                      onTypeChanged: (t) => setState(() => _docType = t),
                      controller: _digits,
                      validator: validateNationalIdDigits,
                    ),
                    const SizedBox(height: 24),
                    if (_exists) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.gold100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, size: 18, color: AppColors.gold800),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.existsMessage,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: AppColors.gold800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
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
                    PrimaryButton(label: 'Continuar', loading: _loading, onPressed: _submit),
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
