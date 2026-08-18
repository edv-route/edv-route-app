import 'package:flutter/material.dart';

import '../../../../shared/widgets/auth_header.dart';
import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/driver.dart';
import '../widgets/dashboard_tile.dart';

/// Driver home tab — intentionally simple for now: a greeting, an availability
/// card and a few entry tiles. Real data/actions are wired in later phases.
class DashboardScreen extends StatefulWidget {
  final Driver driver;

  const DashboardScreen({super.key, required this.driver});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late bool _available = widget.driver.isAvailable;

  void _soon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.driver.fullName.split(' ').first;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AuthHeader(
          title: 'Hola, $firstName',
          subtitle: 'Bienvenido a tu panel',
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _AvailabilityCard(
                available: _available,
                onChanged: (v) {
                  setState(() => _available = v);
                  _soon('La sincronización de disponibilidad llega pronto.');
                },
              ),
              const SizedBox(height: 16),
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

class _AvailabilityCard extends StatelessWidget {
  final bool available;
  final ValueChanged<bool> onChanged;

  const _AvailabilityCard({required this.available, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.gold100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  available ? 'Disponible' : 'No disponible',
                  style: const TextStyle(color: AppColors.gold900, fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: available,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }
}
