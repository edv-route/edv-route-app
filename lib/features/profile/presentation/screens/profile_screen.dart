import 'package:flutter/material.dart';
import '../../../../core/utils/money.dart';

import '../../../../core/config/app_build.dart';
import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../domain/entities/alta_debt.dart';
import '../../../../shared/widgets/driver_header.dart';
import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/driver.dart';
import '../../../../domain/entities/enrollment_cost.dart';
import '../../../enrollment/presentation/controllers/checklist_controller.dart';
import '../../../enrollment/presentation/screens/alta_payment_screen.dart';
import '../../../enrollment/presentation/advance_payment_flow.dart';
import '../../../enrollment/presentation/screens/documents_list_screen.dart';
import '../../../enrollment/presentation/screens/vehicles_list_screen.dart';
import '../../../../shared/widgets/checklist_widgets.dart';
import '../../../../shared/widgets/media_picker.dart';
import '../availability_action.dart';
import '../controllers/profile_controller.dart';
import './edit_profile_screen.dart';
import '../../../../shared/actions/logout_action.dart';

/// Driver profile tab for an operating affiliate: identity + rating, account
/// standing (dues / next payment), navigable documents and vehicles (reusing the
/// checklist screens in read-only), membership benefits and personal data.
/// Trips/history are a separate module, not here yet.
class ProfileScreen extends StatefulWidget {
  final Driver driver;

  /// The shell owns the driver; this reports edits (data, photo, duty) back.
  final ValueChanged<Driver> onDriverChanged;

  /// Bell state, owned by the shell so both tabs show the same number.
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;

  const ProfileScreen({
    super.key,
    required this.driver,
    required this.onDriverChanged,
    required this.onNotificationsTap,
    this.unreadNotifications = 0,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _profile =
      ProfileController(
        Dependencies.instance.accountRepository,
        Dependencies.instance.catalogsRepository,
      );
  late final ChecklistController _checklist =
      ChecklistController(
        Dependencies.instance.enrollmentRepository,
        Dependencies.instance.catalogsRepository,
      );

  @override
  void initState() {
    super.initState();
    _profile.load();
    _checklist.load();
  }

  @override
  void dispose() {
    _profile.dispose();
    _checklist.dispose();
    super.dispose();
  }

  void _openDocuments() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocumentsListScreen(controller: _checklist)),
    );
  }

  void _openVehicles() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VehiclesListScreen(controller: _checklist)),
    );
  }

  void _openPayment() {
    // Stacked, NOT the entrance: he is already inside the app and must be able
    // to come back — with or without the payment sent.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AltaPaymentScreen(driver: widget.driver, isEntrance: false),
      ),
    );
  }

  bool _savingAvailability = false;

  Future<void> _setAvailability(bool value) async {
    setState(() => _savingAvailability = true);
    await applyAvailability(
      context: context,
      driver: widget.driver,
      available: value,
      onDriverChanged: widget.onDriverChanged,
    );
    if (mounted) setState(() => _savingAvailability = false);
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<Driver>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(driver: widget.driver)),
    );
    if (updated != null && mounted) widget.onDriverChanged(updated);
  }

  /// Picks a photo and replaces the profile one. The backend answers with the
  /// fresh signed URL, so the header repaints without reloading the session.
  Future<void> _changePhoto() async {
    final image = await pickPhoto(context);
    if (image == null || !mounted) return;
    try {
      final url = await _profile.uploadPhoto(image);
      if (!mounted) return;
      widget.onDriverChanged(widget.driver.copyWith(photoUrl: url));
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('No se pudo actualizar tu foto. Intenta de nuevo.');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  @override
  Widget build(BuildContext context) {
    // Header pinned OUTSIDE the scroll so the OS status bar (clock/battery) always
    // sits over the red header, never over scrolled light content — fixes the
    // overlap on notch/punch-hole phones across Android versions.
    return Column(
      children: [
        DriverHeader(
          driver: widget.driver,
          available: widget.driver.isAvailable,
          savingAvailability: _savingAvailability,
          onAvailabilityChanged: _savingAvailability ? null : _setAvailability,
          onEdit: _openEdit,
          onPhotoTap: _changePhoto,
          photoBusy: _profile.uploadingPhoto,
          unreadNotifications: widget.unreadNotifications,
          onNotificationsTap: widget.onNotificationsTap,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _accountSection(),
              const SizedBox(height: 16),
              _sectionLabel('Tu solicitud'),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: _checklist,
                builder: (context, _) {
                  final c = _checklist.checklist;
                  return Column(
                    children: [
                      ChecklistTile(
                        icon: Icons.description_outlined,
                        title: 'Documentos',
                        subtitle: c == null ? 'Ver tus documentos' : '${c.driverDocuments.length} documentos',
                        onTap: _openDocuments,
                      ),
                      ChecklistTile(
                        icon: Icons.directions_car_outlined,
                        title: 'Vehículos',
                        subtitle: c == null
                            ? 'Ver tus vehículos'
                            : '${c.vehicleCount} ${c.vehicleCount == 1 ? 'vehículo' : 'vehículos'}',
                        onTap: _openVehicles,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              _benefitsSection(),
              const SizedBox(height: 16),
              _sectionLabel('Tus datos'),
              const SizedBox(height: 8),
              _InfoCard(
                rows: [
                  ('Cédula', widget.driver.nationalId ?? '—'),
                  ('Teléfono', widget.driver.phone ?? '—'),
                  ('Correo', widget.driver.email ?? '—'),
                ],
              ),
              const SizedBox(height: 24),
              // Which build is installed: a bug reported without it costs a round
              // trip figuring out whether the fix was even in the driver's hands.
              if (AppBuild.label.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'EDV Route ${AppBuild.label}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => performLogout(context),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    minimumSize: const Size.fromHeight(50),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accountSection() {
    return ListenableBuilder(
      listenable: _profile,
      builder: (context, _) {
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
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Estado de cuenta',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                  ),
                  _standingBadge(),
                ],
              ),
              const SizedBox(height: 12),
              _accountBody(),
            ],
          ),
        );
      },
    );
  }

  Widget _standingBadge() {
    if (_profile.loading || _profile.debt == null) return const SizedBox.shrink();
    final debt = _profile.debt!;
    final account = _profile.account;
    if (debt.hasPendingPayment) {
      return const _Pill(label: 'Pago en revisión', bg: AppColors.gold100, fg: AppColors.gold800);
    }
    // The engine's status wins over the debt total: a penalized driver who
    // already settled still does NOT operate until his reactivation moment.
    if (account != null && account.isPenalized) {
      return const _Pill(label: 'Penalizado', bg: AppColors.primary100, fg: AppColors.primary800);
    }
    if (debt.hasDebt) {
      final weeks = account?.weeksOwed ?? 0;
      return _Pill(
        label: weeks > 0 ? 'Debes $weeks ${weeks == 1 ? 'semana' : 'semanas'}' : 'Debes',
        bg: AppColors.primary100,
        fg: AppColors.primary800,
      );
    }
    return const _Pill(label: 'Al día', bg: Color(0xFFDCFCE7), fg: Color(0xFF166534));
  }

  Widget _accountBody() {
    if (_profile.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final debt = _profile.debt;
    if (debt == null) {
      return Text(
        _profile.error ?? 'No se pudo cargar tu cuenta.',
        style: const TextStyle(fontSize: 13, color: AppColors.muted),
      );
    }
    if (debt.hasPendingPayment) {
      return const Text(
        'Registraste un pago y un administrador lo está revisando. Te avisaremos cuando quede confirmado.',
        style: TextStyle(fontSize: 13, color: AppColors.ink, height: 1.35),
      );
    }
    if (debt.hasDebt) {
      final lines = _groupedDebt(debt);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Two identical "Tarifa de la semana" rows told the driver nothing: he
          // could not tell he was two weeks behind. This says it in words first.
          _debtHeadline(lines),
          const SizedBox(height: 12),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      line.count > 1 ? '${line.label}  ×${line.count}' : line.label,
                      style: const TextStyle(fontSize: 13, color: AppColors.ink),
                    ),
                  ),
                  Text(formatUsd(line.amountUsd),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                ],
              ),
            ),
          const Divider(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text('Total a pagar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              Text(debt.totalLabel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary700)),
            ],
          ),
          _coverageLines(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _openPayment,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(46)),
              child: const Text('Pagar'),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Estás al día con tus pagos.',
          style: TextStyle(fontSize: 13, color: AppColors.ink, height: 1.35),
        ),
        _coverageLines(),
        _advanceLink(),
      ],
    );
  }

  /// Prepay weeks while up to date.
  ///
  /// A LINK, not a button, and only in this branch: the driver who owes gets a
  /// solid «Pagar» because it is urgent, and this one gets a quiet line because
  /// it is optional. The visual weight is what tells the two apart without
  /// reading a word — which is the whole point of showing it only here.
  ///
  /// Until now an affiliate with zero debt had no way to pay ANYTHING from the
  /// app: the screen simply said he was up to date and ended there.
  Widget _advanceLink() {
    final account = _profile.account;
    // Needs a weekly price to quote with. Without it the link would lead to a
    // screen that cannot compute a total.
    if (account?.planPriceUsd == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: _openAdvance,
        child: Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.cardGrey)),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Adelantar pago',
                  style: TextStyle(fontSize: 13.5, color: AppColors.primary700),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: AppColors.primary700),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAdvance() async {
    final account = _profile.account;
    if (account == null) return;
    // The reload runs INSIDE the flow, before the sheet closes, so the card is
    // already showing «Pago en revisión» when it comes back into view.
    await runAdvancePaymentFlow(
      context,
      account: account,
      onSubmitted: () => _profile.load(),
    );
  }

  /// Repeated concepts collapsed into one line with a count: a driver two weeks
  /// behind saw the same row twice and read it as a glitch, not as two weeks.
  List<_DebtLine> _groupedDebt(AltaDebt debt) {
    final grouped = <String, _DebtLine>{};
    for (final item in debt.items) {
      final current = grouped[item.label];
      grouped[item.label] = _DebtLine(
        label: item.label,
        count: (current?.count ?? 0) + 1,
        amountUsd: (current?.amountUsd ?? 0) + item.amountUsd,
      );
    }
    return grouped.values.toList();
  }

  /// "Debes 2 semanas de tarifa y tu membresía" — built from the very lines shown
  /// below, so the sentence and the breakdown can never disagree.
  Widget _debtHeadline(List<_DebtLine> lines) {
    final parts = lines.map((l) => l.phrase).toList();
    final text = parts.length <= 1
        ? (parts.isEmpty ? 'Tienes pagos pendientes' : 'Debes ${parts.first}')
        : 'Debes ${parts.sublist(0, parts.length - 1).join(', ')} y ${parts.last}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.primary700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: AppColors.primary800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Coverage detail: until when he is paid up, what he pays next and when, and
  /// — if he is penalized and already settled — when the office reactivates him.
  /// Absent when the standing could not be loaded (the debt card still works).
  Widget _coverageLines() {
    final account = _profile.account;
    if (account == null) return const SizedBox.shrink();

    final rows = <(IconData, String)>[];
    if (account.paidUntil != null) {
      // A date in the past is NOT coverage: it is the day it ran out, and it is
      // usually the reason he owes. Saying "cubierto hasta" there reads as if he
      // were fine.
      final expired = account.paidUntil!.isBefore(DateTime.now());
      rows.add((
        expired ? Icons.event_busy_outlined : Icons.event_available_outlined,
        expired
            ? 'Tu semana pagada venció el ${formatDisplayDate(account.paidUntil!)}'
            : 'Cubierto hasta el ${formatDisplayDate(account.paidUntil!)}',
      ));
    }
    final amount = account.nextAmountUsd;
    final date = account.nextChargeDate;
    if (date != null) {
      // An ISSUED charge is already payable; one not issued yet is only announced.
      final verb = account.upcoming != null ? 'Próximo pago' : 'Próximo cobro';
      final money = amount == null ? '' : ' de ${formatUsd(amount)}';
      rows.add((Icons.schedule, '$verb$money el ${formatDisplayDate(date)}'));
    }
    if (account.awaitingReactivation) {
      rows.add((
        Icons.lock_clock,
        'Ya pagaste. Vuelves a estar activo el ${formatDisplayDate(account.reactivatesAt!)}',
      ));
    } else if (account.isPenalized) {
      rows.add((
        Icons.report_gmailerrorred_outlined,
        'Estás penalizado por pasar de ${account.capWeeks} semanas de deuda. Paga para volver a operar.',
      ));
    } else if (account.isPaused) {
      rows.add((Icons.pause_circle_outline, 'Tu cuenta está en pausa. Contacta a la oficina.'));
    } else if (account.startsLater) {
      // Approved with a programmed start: he is early, not blocked. The home
      // carries the full notice; here it stands with the rest of his standing.
      rows.add((
        Icons.event_available_outlined,
        'Empiezas a trabajar el ${formatDisplayDate(account.tariffStartsAt!)}',
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(row.$1, size: 15, color: AppColors.muted),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _benefitsSection() {
    return ListenableBuilder(
      listenable: _profile,
      builder: (context, _) {
        final MembershipInfo? m = _profile.membership;
        if (m == null || m.benefits.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _sectionLabel('Beneficios de tu membresía'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final b in m.benefits)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(b.name, style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted),
      );
}

/// Colored pill for the account standing.
/// One concept of the debt after grouping its repeats (2 weeks = one line, ×2).
class _DebtLine {
  final String label;
  final int count;
  final double amountUsd;

  const _DebtLine({required this.label, required this.count, required this.amountUsd});

  /// The concept in words, for the headline sentence.
  String get phrase {
    final plural = count > 1;
    if (label.startsWith('Tarifa')) return plural ? '$count semanas de tarifa' : '1 semana de tarifa';
    if (label.startsWith('Penaliza')) return plural ? '$count penalizaciones' : '1 penalización';
    if (label.startsWith('Membres')) return 'tu membresía';
    return plural ? '$count × $label' : label;
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
      );
}

class _InfoCard extends StatelessWidget {
  final List<(String, String)> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      rows[i].$1,
                      style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].$2,
                      style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
