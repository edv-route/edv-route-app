import 'package:flutter/material.dart';

import '../../../../shared/widgets/driver_header.dart';
import '../../../../domain/entities/driver.dart';
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
