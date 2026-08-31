import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/location/location_service.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';

/// Asks for location before turning tracking on, with the reason first.
///
/// The permission model, because it is easy to get backwards: **"Mientras usas
/// la app" is enough**. A foreground service of type `location`, started while
/// the app is open, keeps receiving positions after it is closed. "Permitir todo
/// el tiempo" only adds surviving a reboot on its own — and since Android 11 it
/// is not even in the dialog, only in system settings.
///
/// So it is offered as an EXTRA, once tracking already works. Blocking on it
/// would be blocking on the step most people never complete, for a benefit most
/// of them will never notice.
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen>
    with WidgetsBindingObserver {
  final _service = LocationService();
  bool _asking = false;
  String? _error;

  /// Tracking is on; what is left is the optional reboot-proofing.
  bool _tracking = false;

  @override
  void initState() {
    super.initState();
    // Coming back from system settings is not an event the screen gets told
    // about, so the lifecycle is what tells us to re-check.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _tracking) _refreshExtra();
  }

  Future<void> _refreshExtra() async {
    if (await _service.hasBackgroundPermission() && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _ask() async {
    setState(() {
      _asking = true;
      _error = null;
    });

    final permission = await _service.requestPermission();
    if (!mounted) return;

    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!granted) {
      setState(() {
        _asking = false;
        _error = permission == LocationPermission.deniedForever
            ? 'Lo bloqueaste antes. Ábrelo en Ajustes → Permisos → Ubicación.'
            : 'Sin permiso de ubicación no podemos asignarte carreras.';
      });
      return;
    }

    final started = await _service.start();
    if (!mounted) return;

    if (!started) {
      setState(() {
        _asking = false;
        _error = 'No se pudo activar. Intenta de nuevo.';
      });
      return;
    }

    // Already working. Whether he takes the extra step is up to him.
    if (permission == LocationPermission.always) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _asking = false;
      _tracking = true;
    });
  }

  /// Sends the driver to the location permission screen in one tap.
  ///
  /// Asking for the background permission is what opens it (Android 11+
  /// moved "Permitir todo el tiempo" out of the dialog and into settings).
  /// If the request resolves without granting it — already denied for good,
  /// or a phone that behaves differently — we fall back to the app settings
  /// page, which is where this used to send everyone.
  Future<void> _openBackgroundSettings() async {
    final granted = await _service.requestBackgroundPermission();
    if (!mounted) return;
    if (granted) {
      Navigator.of(context).pop(true);
      return;
    }
    if (await _service.hasBackgroundPermission()) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }
    await _service.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AuthHeader(
            showBack: true,
            title: _tracking ? 'Ya estás compartiendo' : 'Compartir tu ubicación',
            subtitle: _tracking ? 'Falta un detalle opcional' : 'Necesario para recibir carreras',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: _tracking ? _extraStep() : _firstStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _firstStep() {
    return Column(
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
          body: 'Mientras compartes tu ubicación verás un aviso fijo de EDV Route en la barra de tu teléfono.',
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
            'Elige "Mientras la app está en uso". Con eso basta: seguimos recibiendo tu ubicación aunque cierres la app, mientras estés activo.',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.primary900),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _ErrorText(_error!),
        ],
        const SizedBox(height: 24),
        PrimaryButton(label: 'Permitir ubicación', loading: _asking, onPressed: _ask),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
          child: const Text('Ahora no'),
        ),
      ],
    );
  }

  /// The optional extra. Framed as a bonus, never as a problem: tracking is
  /// already running by the time this shows.
  Widget _extraStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 24, color: Color(0xFF166534)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Listo, ya estamos recibiendo tu ubicación mientras estés activo.',
                style: TextStyle(fontSize: 15, height: 1.4, color: AppColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Un detalle opcional',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        const Text(
          'Si reinicias el teléfono, tendrás que abrir la app para seguir compartiendo. Para que se reanude solo, elige "Permitir todo el tiempo" en los ajustes.',
          style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Ajustes → Permisos → Ubicación → Permitir todo el tiempo.\n\nAndroid ya no ofrece esa opción en la ventana de permisos: solo se puede elegir ahí.',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.ink),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Abrir ajustes', onPressed: _openBackgroundSettings),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: const Text('Así está bien'),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      );
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
