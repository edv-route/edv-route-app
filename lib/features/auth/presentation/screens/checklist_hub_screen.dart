import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../theme/app_colors.dart';
import '../../../home/presentation/screens/driver_root_screen.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/driver.dart';
import '../controllers/checklist_controller.dart';
import '../widgets/checklist_widgets.dart';
import 'documents_list_screen.dart';
import 'vehicles_list_screen.dart';

/// "Completa tu solicitud" — the applicant's home. Owns the single
/// [ChecklistController] shared with every sub-screen (documents / vehicles /
/// detail) so there is one `/me/checklist` load and every screen reacts to the
/// same state. Instead of one long list, it offers two sections the applicant
/// navigates into freely (non-blocking).
///
/// It also watches the driver's status: when the admin approves the solicitud the
/// applicant becomes `approved`, and the hub routes on to the payment screen on
/// app resume / pull-to-refresh — no need to log out and back in.
class ChecklistHubScreen extends StatefulWidget {
  const ChecklistHubScreen({super.key});

  @override
  State<ChecklistHubScreen> createState() => _ChecklistHubScreenState();
}

class _ChecklistHubScreenState extends State<ChecklistHubScreen> with WidgetsBindingObserver {
  late final ChecklistController _controller =
      ChecklistController(Dependencies.instance.registrationRepository);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning to the app: the solicitud may have just been approved/rejected by
    // an admin, so re-check and route on without forcing a logout.
    if (state == AppLifecycleState.resumed) _syncDriverStatus();
  }

  /// Pull-to-refresh: reload the checklist AND re-check the driver's status.
  Future<void> _refresh() async {
    await _controller.load();
    await _syncDriverStatus();
  }

  /// If the solicitud is no longer `applicant` (approved/rejected/…), leave the hub
  /// for the right screen (payment, status, …). A transport error is ignored so
  /// the applicant simply stays on the checklist.
  Future<void> _syncDriverStatus() async {
    Driver? driver;
    try {
      driver = await Dependencies.instance.authRepository.currentDriver();
    } catch (_) {
      return;
    }
    final d = driver;
    if (!mounted || d == null || d.status == DriverStatus.applicant) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DriverRootScreen(driver: d)),
    );
  }

  Future<void> _logout() async {
    await Dependencies.instance.tokenStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.selection, (_) => false);
  }

  void _openDocuments() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocumentsListScreen(controller: _controller)),
    );
  }

  void _openVehicles() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VehiclesListScreen(controller: _controller)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: 'Completa tu solicitud',
            subtitle: 'Sube lo que falta para que revisemos tu ingreso',
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_controller.error != null) {
                  return ChecklistErrorState(message: _controller.error!, onRetry: _controller.load);
                }
                return _content(_controller.checklist);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(Checklist? checklist) {
    if (checklist == null) return const SizedBox.shrink();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          ChecklistStatusBanner(checklist: checklist),
          const SizedBox(height: 20),
          SectionCard(
            icon: Icons.description_outlined,
            title: 'Documentos',
            subtitle: _documentsSubtitle(checklist),
            needsAttention: checklist.driverActionable > 0,
            onTap: _openDocuments,
          ),
          const SizedBox(height: 12),
          SectionCard(
            icon: Icons.directions_car_outlined,
            title: 'Vehículos',
            subtitle: _vehiclesSubtitle(checklist),
            needsAttention: checklist.vehicleCount == 0 || checklist.vehiclesActionable > 0,
            onTap: _openVehicles,
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Cerrar sesión'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary900),
          ),
        ],
      ),
    );
  }

  /// "2 de 3 aprobados · 1 por resolver" — a compact progress line for the card.
  String _documentsSubtitle(Checklist c) {
    if (c.driverTotal == 0) return 'Sin documentos requeridos por ahora';
    final base = '${c.driverApproved} de ${c.driverTotal} aprobados';
    if (c.driverActionable > 0) return '$base · ${c.driverActionable} por resolver';
    return base;
  }

  String _vehiclesSubtitle(Checklist c) {
    if (c.vehicleCount == 0) return 'Falta agregar tu vehículo (obligatorio)';
    final noun = c.vehicleCount == 1 ? 'vehículo' : 'vehículos';
    final base = '${c.vehicleCount} $noun';
    if (c.vehiclesActionable > 0) return '$base · ${c.vehiclesActionable} por resolver';
    if (c.vehiclesApproved == c.vehicleCount) return '$base · aprobado${c.vehicleCount == 1 ? '' : 's'}';
    return '$base · en revisión';
  }
}
