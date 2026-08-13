import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
// home <- auth cross-reference: an already-settled driver enters the app shell.
import '../../../home/presentation/screens/driver_shell.dart';
import '../../domain/entities/alta_debt.dart';
import '../../domain/entities/driver.dart';
import '../../domain/repositories/registration_repository.dart' show PaymentCapture;
import '../controllers/alta_payment_controller.dart';
import '../widgets/payment_draft_sheet.dart';

/// Deferred alta payment (solicitudes-app): once the admin approves the solicitud,
/// the driver is `approved` with his base debt (membership + first week). This
/// screen shows the breakdown, takes the terms acceptance and captures the payment
/// (purpose=`debt`), left pending for review. Already-settled drivers pass through
/// to the app shell; a payment under review shows a waiting state.
class AltaPaymentScreen extends StatefulWidget {
  final Driver driver;

  const AltaPaymentScreen({super.key, required this.driver});

  @override
  State<AltaPaymentScreen> createState() => _AltaPaymentScreenState();
}

class _AltaPaymentScreenState extends State<AltaPaymentScreen> {
  late final AltaPaymentController _controller =
      AltaPaymentController(Dependencies.instance.registrationRepository);
  bool _acceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _controller.load().then((_) {
      if (!mounted) return;
      final debt = _controller.debt;
      // Nothing to pay and nothing under review → an operating driver: go straight
      // to the app shell instead of showing him a payment screen every launch.
      if (debt != null && !debt.hasDebt && !debt.hasPendingPayment) {
        _enterApp();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await Dependencies.instance.tokenStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.selection, (_) => false);
  }

  void _enterApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DriverShell(driver: widget.driver)),
    );
  }

  Future<void> _pay() async {
    final debt = _controller.debt;
    if (debt == null) return;
    final item = await showPaymentSheet(
      context,
      methods: _controller.methods,
      totalLabel: debt.totalLabel,
    );
    if (item == null || !mounted) return;
    final ok = await _controller.submit(
      PaymentCapture(
        paymentMethodId: item.paymentMethodId,
        reference: item.reference,
        payerBank: item.payerBank,
        paidOn: item.paidOn,
        payerPhone: item.payerPhone,
        payerId: item.payerId,
        payerAccount: item.payerAccount,
        receipt: item.receipt,
      ),
      acceptedTerms: _acceptedTerms,
    );
    if (!ok && _controller.error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_controller.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: 'Paga tu alta',
            subtitle: 'Tu ingreso fue aprobado. Registra el pago para activarte.',
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_controller.error != null && _controller.debt == null) {
                  return _ErrorState(message: _controller.error!, onRetry: _controller.load);
                }
                final debt = _controller.debt!;
                if (_controller.submitted || debt.hasPendingPayment) {
                  return _PendingState(onLogout: _logout);
                }
                if (!debt.hasDebt) {
                  return _SettledState(onEnter: _enterApp);
                }
                return _payContent(debt);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _payContent(AltaDebt debt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DebtCard(debt: debt),
          const SizedBox(height: 20),
          _TermsCheck(
            value: _acceptedTerms,
            onChanged: (v) => setState(() => _acceptedTerms = v),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Registrar pago',
            loading: _controller.submitting,
            onPressed: _acceptedTerms ? _pay : null,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Cerrar sesión'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary900),
            ),
          ),
        ],
      ),
    );
  }
}

/// Debt breakdown card: one line per concept + the total to pay.
class _DebtCard extends StatelessWidget {
  final AltaDebt debt;

  const _DebtCard({required this.debt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Detalle de tu alta',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          for (final it in debt.items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(it.label, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
                ),
                Text(
                  '\$${it.amountUsd.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const Divider(height: 8),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total a pagar',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              Text(
                debt.totalLabel,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Terms & conditions acceptance required to pay.
class _TermsCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _TermsCheck({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'He leído y acepto los Términos y Condiciones del servicio.',
              style: TextStyle(fontSize: 13.5, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown after paying (or when a payment is already under review).
class _PendingState extends StatelessWidget {
  final Future<void> Function() onLogout;

  const _PendingState({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top, color: AppColors.gold600, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Tu pago está en revisión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'Un administrador lo verificará y activaremos tu cuenta. '
              'Te avisaremos cuando esté listo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Cerrar sesión'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary900),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when there is nothing to pay (debt already settled) — enter the app.
class _SettledState extends StatelessWidget {
  final VoidCallback onEnter;

  const _SettledState({required this.onEnter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Color(0xFF16A34A), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Tu alta está al día',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(label: 'Entrar a la app', onPressed: onEnter),
            ),
          ],
        ),
      ),
    );
  }
}

/// Load-failure state with a retry.
class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.muted, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
