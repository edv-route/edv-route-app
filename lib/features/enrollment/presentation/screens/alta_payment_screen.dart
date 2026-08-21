import 'package:flutter/material.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money.dart';

import '../../../../core/di.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
// home <- auth cross-reference: an already-settled driver enters the app shell.
import '../../../home/presentation/screens/driver_shell.dart';
import '../../../home/presentation/screens/driver_status_screen.dart';
import '../../../../domain/entities/alta_debt.dart';
import '../../../../domain/entities/driver.dart';
import '../../../../domain/repositories/enrollment_repository.dart' show PaymentCapture;
import '../controllers/alta_payment_controller.dart';
import '../controllers/alta_screen_state.dart';
import '../widgets/payment_draft_sheet.dart';

/// Deferred alta payment (solicitudes-app): once the admin approves the solicitud,
/// the driver is `approved` with his base debt (membership + first week). This
/// screen shows the breakdown, takes the terms acceptance and captures the payment
/// (purpose=`debt`), left pending for review. Already-settled drivers pass through
/// to the app shell; a payment under review shows a waiting state.
class AltaPaymentScreen extends StatefulWidget {
  final Driver driver;

  /// True when this is the ENTRANCE gate (routed from `DriverRootScreen`): the
  /// driver is not inside the app yet, so the ways out are entering once settled
  /// or logging out.
  ///
  /// False when an affiliate who is ALREADY WORKING opened it from his profile
  /// to report a payment. Then it is one more stacked screen: the way out is
  /// going back, there is no logout, and above all it must never replace the
  /// shell — he was already in it.
  final bool isEntrance;

  /// Weeks to PREPAY while up to date. Null = the ordinary flow (settle the debt
  /// or pay the alta). Chosen BEFORE this screen opens, because "adelantar"
  /// means nothing until the driver knows how many weeks he is buying.
  final int? advanceWeeks;

  const AltaPaymentScreen({
    super.key,
    required this.driver,
    this.isEntrance = true,
    this.advanceWeeks,
  });

  @override
  State<AltaPaymentScreen> createState() => _AltaPaymentScreenState();
}

class _AltaPaymentScreenState extends State<AltaPaymentScreen> {
  late final AltaPaymentController _controller =
      AltaPaymentController(
    Dependencies.instance.enrollmentRepository,
    Dependencies.instance.accountRepository,
    Dependencies.instance.catalogsRepository,
  );
  bool get _isAdvance => widget.advanceWeeks != null;

  bool _acceptedTerms = false;
  int _weeks = 1; // total weeks paid at the alta (1 = base only; more = advance)

  @override
  void initState() {
    super.initState();
    _controller.load(advance: _isAdvance).then((_) {
      if (!mounted) return;
      // Only the ENTRANCE forwards anyone. Opened from the profile this screen
      // is stacked on top of the shell, and pushing another shell over it would
      // duplicate the app the driver is already using.
      if (!widget.isEntrance) return;
      final debt = _controller.debt;
      // Settled AND the admin already set the tariff start → an operating driver:
      // go straight to the app shell. Any other case stays on this screen, which
      // picks what to show with the SAME rule (no second, drifting copy of it).
      if (debt != null &&
          altaScreenState(
                hasDebt: debt.hasDebt,
                hasPendingPayment: debt.hasPendingPayment,
                justSubmitted: false,
                isApproved: widget.driver.status == DriverStatus.approved,
                tariffStarted: widget.driver.tariffStarted,
              ) ==
              AltaScreenState.settled) {
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

  /// Back to wherever he came from (the profile). Only for the stacked screen.
  void _goBack() => Navigator.of(context).maybePop();

  void _enterApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DriverShell(driver: widget.driver)),
    );
  }

  /// Total to pay for the chosen number of weeks: base debt + advance weeks.
  double _totalFor(AltaDebt debt) =>
      debt.totalUsd + (debt.weeklyTariffUsd ?? 0) * (_weeks - 1);

  /// An advance is priced by the tariff alone (weeks × weekly price); a debt
  /// payment by what is owed plus any extra weeks at the alta.
  double _amountToCharge(AltaDebt debt) => _isAdvance
      ? (debt.weeklyTariffUsd ?? 0) * widget.advanceWeeks!
      : _totalFor(debt);

  Future<void> _pay() async {
    final debt = _controller.debt;
    if (debt == null) return;
    final total = _amountToCharge(debt);
    final item = await showPaymentSheet(
      context,
      methods: _controller.methods,
      totalLabel: formatUsd(total),
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
      weeks: widget.advanceWeeks ?? _weeks,
      advance: _isAdvance,
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
          // The entrance is still "paga tu alta". From the profile it is a
          // payment like any other — telling a driver who has been working for
          // weeks to "register the payment to activate himself" is simply false.
          AuthHeader(
            title: _isAdvance
                ? 'Adelantar pago'
                : (widget.isEntrance ? 'Paga tu alta' : 'Reportar pago'),
            subtitle: _isAdvance
                ? 'Registra el pago de las semanas que adelantas.'
                : (widget.isEntrance
                    ? 'Tu ingreso fue aprobado. Registra el pago para activarte.'
                    : 'Registra el pago que ya hiciste. Un administrador lo revisará.'),
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
                final state = widget.isEntrance
                    ? altaScreenState(
                        hasDebt: debt.hasDebt,
                        hasPendingPayment: debt.hasPendingPayment,
                        justSubmitted: _controller.submitted,
                        isApproved: widget.driver.status == DriverStatus.approved,
                        tariffStarted: widget.driver.tariffStarted,
                      )
                    : reportPaymentState(
                        // An advance is payable BECAUSE there is no debt, so it
                        // enters the form as if there were something to pay. A
                        // payment already under review still wins — the backend
                        // would refuse a second one anyway.
                        hasDebt: debt.hasDebt || _isAdvance,
                        hasPendingPayment: debt.hasPendingPayment,
                        justSubmitted: _controller.submitted,
                      );
                switch (state) {
                  case AltaScreenState.paymentUnderReview:
                    return _PendingState(
                      onLogout: widget.isEntrance ? _logout : null,
                      onBack: widget.isEntrance ? null : _goBack,
                    );
                  case AltaScreenState.pay:
                    return _payContent(debt);
                  // Still `pending` and owing nothing: it is the ADMIN's turn.
                  case AltaScreenState.applicationUnderReview:
                    return DriverStatusScreen(driver: widget.driver);
                  // Paid, but the admin hasn't set the tariff start yet: approved
                  // and does NOT operate until then — a waiting screen, never home.
                  case AltaScreenState.waitingTariffStart:
                    return _WaitingStartState(onLogout: _logout);
                  case AltaScreenState.settled:
                    return _SettledState(onEnter: _enterApp);
                  case AltaScreenState.nothingOwed:
                    return _NothingOwedState(onBack: _goBack);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _payContent(AltaDebt debt) {
    final weekly = debt.weeklyTariffUsd;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Before anything else: his last payment was turned down and why. It
          // goes ABOVE the breakdown because without it the screen looks like he
          // never sent one, and he resends the same rejected proof.
          if (debt.rejected != null) ...[
            _RejectedCard(rejection: debt.rejected!),
            const SizedBox(height: 16),
          ],
          // An advance already chose its weeks in the sheet before this screen,
          // so here it only confirms the number and the amount. Showing the
          // weeks selector again would let him change what he already decided
          // and quietly disagree with the total the sheet quoted him.
          if (_isAdvance)
            _AdvanceSummary(
              weeks: widget.advanceWeeks!,
              weeklyTariff: weekly ?? 0,
              total: _amountToCharge(debt),
            )
          else ...[
            _DebtCard(debt: debt, weeks: _weeks, total: _totalFor(debt)),
            if (weekly != null) ...[
              const SizedBox(height: 16),
              _WeeksSelector(
                weeks: _weeks,
                weeklyTariff: weekly,
                onChanged: (w) => setState(() => _weeks = w),
              ),
            ],
          ],
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
          // Logging out is an exit only for someone who has not come in yet. An
          // affiliate reporting a payment from his profile gets «Cancelar»: he
          // is inside the app and this is one screen, not a gate.
          Center(
            child: widget.isEntrance
                ? TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Cerrar sesión'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary900),
                  )
                : TextButton(
                    onPressed: _goBack,
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary900),
                    child: const Text('Cancelar'),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The admin turned his last payment down: how much it was, when, and the reason
/// he typed. Shown until the driver sends a new payment (the backend clears it).
class _RejectedCard extends StatelessWidget {
  final AltaDebtRejection rejection;

  const _RejectedCard({required this.rejection});

  @override
  Widget build(BuildContext context) {
    final when = rejection.reviewedAt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, size: 20, color: AppColors.primary700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tu pago de ${rejection.amountLabel} fue rechazado',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary900,
                  ),
                ),
              ),
            ],
          ),
          if (rejection.reason != null) ...[
            const SizedBox(height: 10),
            Text(
              'Motivo: ${rejection.reason}',
              style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.primary900),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            when != null
                ? 'Revisado el ${formatDisplayDate(when)}. Corrige lo indicado y vuelve a enviarlo.'
                : 'Corrige lo indicado y vuelve a enviarlo.',
            style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Debt breakdown card: one line per concept, an advance-weeks line when the
/// applicant chose extra weeks, and the (dynamic) total to pay.
class _DebtCard extends StatelessWidget {
  final AltaDebt debt;
  final int weeks;
  final double total;

  const _DebtCard({required this.debt, required this.weeks, required this.total});

  @override
  Widget build(BuildContext context) {
    final weekly = debt.weeklyTariffUsd ?? 0;
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
          // With advance weeks available, consolidate the weekly line into a single
          // "Tarifa semanal × N" so the breakdown matches the selector's N (avoids
          // the confusing "1 semana + N adelantadas" split).
          if (debt.weeklyTariffUsd != null) ...[
            for (final it in debt.items)
              if (!it.label.toLowerCase().contains('semana')) ...[
                _Line(label: it.label, amount: it.amountUsd),
                const SizedBox(height: 8),
              ],
            _Line(label: 'Tarifa semanal × $weeks', amount: weekly * weeks),
            const SizedBox(height: 8),
          ] else ...[
            for (final it in debt.items) ...[
              _Line(label: it.label, amount: it.amountUsd),
              const SizedBox(height: 8),
            ],
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
                formatUsd(total),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One label + amount row of the breakdown.
class _Line extends StatelessWidget {
  final String label;
  final double amount;

  const _Line({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.ink)),
        ),
        Text(
          formatUsd(amount),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
      ],
    );
  }
}

/// Advance-weeks selector (Forma A): the applicant may prepay extra weeks on top
/// of the mandatory first one. Minimum 1 (the base week).
class _WeeksSelector extends StatelessWidget {
  final int weeks;
  final double weeklyTariff;
  final ValueChanged<int> onChanged;

  const _WeeksSelector({
    required this.weeks,
    required this.weeklyTariff,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cuántas semanas quieres pagar?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'La primera semana es obligatoria; las demás quedan pagadas por adelantado '
            '(${formatUsd(weeklyTariff)} cada una).',
            style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StepBtn(icon: Icons.remove, onTap: weeks > 1 ? () => onChanged(weeks - 1) : null),
              Expanded(
                child: Center(
                  child: Text(
                    '$weeks ${weeks == 1 ? 'semana' : 'semanas'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ),
              ),
              _StepBtn(icon: Icons.add, onTap: () => onChanged(weeks + 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.primary50 : AppColors.cardGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: enabled ? AppColors.primary : AppColors.muted),
        ),
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
///
/// The way out depends on where the driver came from, and getting that wrong is
/// what locked an affiliate out of his own account: at the ENTRANCE the only
/// honest exit is logging out (he cannot come in until the payment is approved),
/// but for someone already working the exit is simply going back to the app.
class _PendingState extends StatelessWidget {
  final Future<void> Function()? onLogout;
  final VoidCallback? onBack;

  const _PendingState({this.onLogout, this.onBack});

  @override
  Widget build(BuildContext context) {
    final entering = onLogout != null;
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
            Text(
              entering
                  ? 'Un administrador lo verificará y activaremos tu cuenta. '
                      'Te avisaremos cuando esté listo.'
                  : 'Un administrador lo verificará. Te avisamos apenas responda, '
                      'y mientras tanto puedes seguir usando la app con normalidad.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 24),
            if (entering)
              TextButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Cerrar sesión'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary900),
              )
            else
              PrimaryButton(label: 'Volver a la app', onPressed: onBack),
          ],
        ),
      ),
    );
  }
}

/// Report-payment screen with nothing to pay: he is up to date. A dead end here
/// would be as wrong as the one above — the way out is going back.
class _NothingOwedState extends StatelessWidget {
  final VoidCallback onBack;

  const _NothingOwedState({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF15803D), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Estás al día',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'No tienes nada pendiente por pagar en este momento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Volver a la app', onPressed: onBack),
          ],
        ),
      ),
    );
  }
}

/// Shown when the alta is paid but the admin hasn't set the tariff start yet: the
/// driver is approved but does NOT operate until the office activates him. (The
/// countdown for a scheduled start will live in the app home later.)
class _WaitingStartState extends StatelessWidget {
  final Future<void> Function() onLogout;

  const _WaitingStartState({required this.onLogout});

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
              '¡Fuiste aprobado!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu pago está confirmado. Solo falta que la oficina active tu cuenta '
              'para que puedas empezar a trabajar. Te avisaremos apenas esté lista.',
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

/// What an advance is about to charge. Read-only on purpose: the weeks were
/// chosen in the sheet, and offering them again here would let the driver change
/// his mind against a total he was already quoted.
class _AdvanceSummary extends StatelessWidget {
  final int weeks;
  final double weeklyTariff;
  final double total;

  const _AdvanceSummary({
    required this.weeks,
    required this.weeklyTariff,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            weeks == 1 ? 'Adelantas 1 semana' : 'Adelantas $weeks semanas',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$weeks × ${formatUsd(weeklyTariff)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
              Text(
                formatUsd(total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
