import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../theme/app_colors.dart';
import '../../../home/presentation/screens/driver_root_screen.dart';
import '../../../../domain/entities/checklist.dart';
import '../../../../domain/entities/driver.dart';
import '../../../../domain/entities/identity.dart';
import '../../../identity/presentation/controllers/identity_flow_controller.dart';
import '../../../identity/presentation/screens/identity_photos_screen.dart';
import '../application_progress.dart';
import '../controllers/checklist_controller.dart';
import '../widgets/application_hub_widgets.dart';
import '../../../../shared/widgets/checklist_widgets.dart';
import './documents_list_screen.dart';
import './vehicles_list_screen.dart';

/// "Completa tu solicitud" — the applicant's home. Owns the single
/// [ChecklistController] shared with every sub-screen (documents / vehicles /
/// detail) so there is one `/me/checklist` load and every screen reacts to the
/// same state. Redesigned 2026-11-12: progress, one highlighted next step and
/// three sections the applicant navigates into freely — identity (the photos),
/// documents and vehicle.
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
      ChecklistController(
    Dependencies.instance.enrollmentRepository,
    Dependencies.instance.catalogsRepository,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.load();
    _loadIdentity();
  }

  /// Identity photos (2026-11-12): their own section. A failed load leaves
  /// the previous value — the section reads "En revisión", never a false
  /// "Falta" that would send him to retake photos he already sent.
  IdentityView? _identity;

  Future<void> _loadIdentity() async {
    try {
      final view = await Dependencies.instance.driverIdentityRepository.load();
      if (mounted) setState(() => _identity = view);
    } catch (_) {
      // keep what we had
    }
  }

  Future<void> _openIdentity() async {
    final flow = IdentityFlowController(repository: Dependencies.instance.driverIdentityRepository);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IdentityPhotosScreen(
          controller: flow,
          loadOnStart: true,
          title: 'Tu identidad',
          highlight: 'identidad',
          subtitle: 'Revisión de la oficina',
          submitLabel: 'Enviar fotos',
          onSubmitted: (ctx) => Navigator.of(ctx).pop(),
        ),
      ),
    );
    flow.dispose();
    await _loadIdentity();
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
    await Future.wait([_controller.load(), _loadIdentity()]);
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

  void _open(HubSection section) {
    switch (section) {
      case HubSection.identity:
        _openIdentity();
      case HubSection.documents:
        _openDocuments();
      case HubSection.vehicle:
        _openVehicles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: Column(
        children: [
          const AuthHeader(
            title: 'Completa tu solicitud',
            highlight: 'solicitud',
            subtitle: 'Te falta poco para empezar a trabajar',
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

  /// Redesign approved by Luis (2026-11-12): progress, ONE next step, and the
  /// three sections — identity, documents, vehicle — each with a plain state.
  Widget _content(Checklist? checklist) {
    if (checklist == null) return const SizedBox.shrink();
    final progress = ApplicationProgress(identity: _identity, checklist: checklist);
    final next = progress.nextStep;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          ProgressSegments(done: progress.doneCount, total: progress.sections.length),
          const SizedBox(height: 14),
          if (next != null)
            NextStepCard(step: next, onTap: () => _open(next.section))
          else if (progress.doneCount < progress.sections.length)
            const WaitingCard(),
          const SizedBox(height: 14),
          HubSectionTile(
            state: progress.identitySection,
            icon: Icons.verified_user_outlined,
            title: 'Identidad',
            subtitle: 'Foto tipo carnet y cédula',
            onTap: _openIdentity,
          ),
          const SizedBox(height: 10),
          HubSectionTile(
            state: progress.documentsSection,
            icon: Icons.description_outlined,
            title: 'Documentos',
            subtitle: _documentsSubtitle(checklist),
            onTap: _openDocuments,
          ),
          const SizedBox(height: 10),
          HubSectionTile(
            state: progress.vehicleSection,
            icon: Icons.directions_car_outlined,
            title: 'Vehículo',
            subtitle: _vehiclesSubtitle(checklist),
            onTap: _openVehicles,
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Cuando las tres secciones estén aprobadas, pasas al pago de inscripción.',
              style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 18),
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

  /// The requirement names, so he knows what "Documentos" holds.
  String _documentsSubtitle(Checklist c) {
    if (c.driverTotal == 0) return 'Sin documentos requeridos por ahora';
    return c.driverDocuments.map((d) => d.requirementName).join(' · ');
  }

  String _vehiclesSubtitle(Checklist c) {
    if (c.vehicleCount == 0) return 'Agrega tu vehículo y sus papeles';
    final name = c.vehicles.first.label;
    return c.vehicleCount == 1 ? name : '$name y ${c.vehicleCount - 1} más';
  }
}
