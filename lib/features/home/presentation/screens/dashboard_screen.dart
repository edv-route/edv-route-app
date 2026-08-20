import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../domain/entities/account_status.dart';
import '../../../../shared/widgets/driver_header.dart';
import '../../../../domain/entities/driver.dart';
import '../../../../theme/app_colors.dart';
import '../widgets/dashboard_tile.dart';
import '../../../profile/presentation/availability_action.dart';

/// Driver home tab — intentionally simple for now: a greeting, an availability
/// card and a few entry tiles. Real data/actions are wired in later phases.
class DashboardScreen extends StatefulWidget {
  final Driver driver;

  /// The shell owns the driver; this reports a change back to it.
  final ValueChanged<Driver> onDriverChanged;

  const DashboardScreen({super.key, required this.driver, required this.onDriverChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _savingAvailability = false;

  /// Only used for the "your start is programmed" notice. Loaded quietly: if it
  /// fails, the home simply shows no notice instead of an error the driver can
  /// do nothing about.
  AccountStatus? _account;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    try {
      final account = await Dependencies.instance.accountRepository.loadAccount();
      if (mounted) setState(() => _account = account);
    } catch (_) {
      // Silent on purpose: this only feeds an informative banner.
    }
  }

  void _soon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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

  @override
  Widget build(BuildContext context) {
    // Header pinned OUTSIDE the scroll, like Perfil: otherwise it slides under
    // the status bar on notch phones.
    return Column(
      children: [
        DriverHeader(
          driver: widget.driver,
          available: widget.driver.isAvailable,
          savingAvailability: _savingAvailability,
          onAvailabilityChanged: _savingAvailability ? null : _setAvailability,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // He was approved with a start date the admin programmed. Until
              // now nothing told him: he only found out by flipping the switch
              // and getting "contacta a la oficina" (2026-08-20).
              if (_account?.startsLater ?? false) ...[
                _StartsLaterNotice(startsAt: _account!.tariffStartsAt!),
                const SizedBox(height: 16),
              ],
              DashboardTile(
                icon: Icons.assignment_outlined,
                title: 'Solicitudes',
                subtitle: 'Viajes y solicitudes entrantes',
                onTap: () => _soon('Solicitudes: próximamente.'),
              ),
              const SizedBox(height: 12),
              DashboardTile(
                icon: Icons.notifications_none,
                title: 'Notificaciones',
                subtitle: 'Novedades de tu cuenta',
                onTap: () => _soon('Notificaciones: próximamente.'),
              ),
              const SizedBox(height: 12),
              DashboardTile(
                icon: Icons.card_giftcard_outlined,
                title: 'Beneficios',
                subtitle: 'Ventajas por ser parte de EDV',
                onTap: () => _soon('Beneficios: próximamente.'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Your start is programmed for X". Shown to an approved driver whose tariff
/// has a date that hasn't arrived: he is not blocked, he is early. Before this
/// the app said nothing, and the only feedback he could get was the refusal
/// when he tried to go active.
class _StartsLaterNotice extends StatelessWidget {
  final DateTime startsAt;

  const _StartsLaterNotice({required this.startsAt});

  static const _weekdays = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
  ];
  static const _months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  /// "lunes 24 de agosto" — the weekday matters: the start is always a Monday
  /// and that is how a driver remembers it.
  String get _longDate =>
      '${_weekdays[startsAt.weekday - 1]} ${startsAt.day} de ${_months[startsAt.month - 1]}';

  int get _daysLeft {
    final today = DateTime.now();
    return DateTime(startsAt.year, startsAt.month, startsAt.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  String get _countdown {
    final days = _daysLeft;
    if (days <= 0) return 'Es hoy.';
    if (days == 1) return 'Es mañana.';
    return 'Faltan $days días.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.gold100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available_outlined,
                size: 22, color: AppColors.gold900),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu ingreso fue aprobado',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Empiezas a trabajar el $_longDate. $_countdown',
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.gold900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ese día podrás ponerte activo y recibir viajes. '
                  'Tu semana de tarifa arranca en esa fecha (${formatDisplayDate(startsAt)}).',
                  style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
