import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/location/location_service.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';

/// Asks for "location all the time", with the reason first.
///
/// This screen exists because of ONE Android behaviour: from Android 10 the
/// background permission is a second, separate prompt, and from Android 11 it is
/// not even a dialog — it drops the user into system settings to pick "Permitir
/// todo el tiempo" by hand. Fired blind, most people deny it or get lost.
///
/// So: say what it is for, say what he will see, and only then ask.
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  final _service = LocationService();
  bool _asking = false;
  String? _message;

  Future<void> _ask() async {
    setState(() {
      _asking = true;
      _message = null;
    });

    final permission = await _service.requestPermission();
    if (!mounted) return;

    if (permission == LocationPermission.always) {
      await _service.start();
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _asking = false;
      _message = permission == LocationPermission.deniedForever
          // Denied for good: no prompt will come back, only system settings.
          ? 'Lo bloqueaste antes. Ábrelo en Ajustes → Aplicaciones → EDV Route → Permisos → Ubicación y elige "Permitir todo el tiempo".'
          : 'Falta elegir "Permitir todo el tiempo". Sin eso solo podemos verte con la app abierta.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            showBack: true,
            title: 'Compartir tu ubicación',
            subtitle: 'Necesario para recibir carreras',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Para asignarte las carreras que tienes cerca, la oficina necesita saber dónde estás mientras trabajas.',
                    style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.ink),
                  ),
                  const SizedBox(height: 24),
                  const _Point(
                    icon: Icons.schedule,
                    title: 'Solo mientras estás activo',
                    body: 'Al ponerte inactivo dejamos de recibir tu ubicación, de inmediato.',
                  ),
                  const SizedBox(height: 18),
                  const _Point(
                    icon: Icons.notifications_active_outlined,
                    title: 'Siempre vas a saber cuándo',
                    body:
                        'Mientras compartes tu ubicación verás un aviso fijo de EDV Route en la barra de tu teléfono.',
                  ),
                  const SizedBox(height: 18),
                  const _Point(
                    icon: Icons.battery_std_outlined,
                    title: 'Poco consumo',
                    body: 'Se toma tu posición cada varios minutos, no todo el tiempo.',
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Android te va a preguntar dos veces. En la segunda, elige "Permitir todo el tiempo": si eliges solo "mientras usas la app", dejaremos de verte en cuanto la cierres.',
                      style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.primary900),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _message!,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Permitir ubicación',
                    loading: _asking,
                    onPressed: _ask,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                    child: const Text('Ahora no'),
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

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
