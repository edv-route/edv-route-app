import 'package:flutter/material.dart';
import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';

import '../../../../shared/widgets/auth_header.dart';
import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/checklist.dart';
import '../../../../domain/entities/registration_drafts.dart';
import '../controllers/checklist_controller.dart';
import '../../../../shared/widgets/checklist_widgets.dart';
import '../widgets/draft_sheet_scaffold.dart';
import '../widgets/vehicle_draft_sheet.dart';
import './vehicle_detail_screen.dart';

/// The applicant's vehicles, one navigable row each, plus "add vehicle". Tapping a
/// row opens its detail (data + its documents). Shares the hub's controller.
class VehiclesListScreen extends StatefulWidget {
  final ChecklistController controller;

  /// Whether the "add vehicle" action is offered. false in read-only contexts
  /// (e.g. an operating driver browsing his vehicles from the profile).
  final bool allowAdd;

  const VehiclesListScreen({super.key, required this.controller, this.allowAdd = true});

  @override
  State<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

/// Puts this vehicle in use. Only shown on an approved one that is not already
/// the current: the backend refuses anything else, so offering it would be a
/// button that always fails.
class _UseButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;

  const _UseButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: busy ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: busy
          ? const SizedBox(
              height: 12,
              width: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Usar'),
    );
  }
}

/// Marks the vehicle the driver is operating with. Filled and with a tick: a
/// pale chip beside an "Aprobado" of the same colour was invisible, which is
/// exactly what Luis reported.
class _InUseBadge extends StatelessWidget {
  const _InUseBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 13, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'En uso',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
}

class _VehiclesListScreenState extends State<VehiclesListScreen> {
  ChecklistController get _controller => widget.controller;

  /// Vehicle whose switch is in flight, to freeze just that row.
  String? _switchingId;

  /// Makes this one the vehicle he works with. The previous is released by the
  /// backend, so the list only has to reload which id is primary.
  Future<void> _usePrimary(String vehicleId) async {
    setState(() => _switchingId = vehicleId);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Dependencies.instance.enrollmentRepository.setPrimaryVehicle(vehicleId);
      // The checklist carries which one is in use, so reloading it repaints the row.
      await _controller.load();
      if (mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Ahora trabajas con este vehículo.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('No se pudo cambiar el vehículo.')));
      }
    }
    if (mounted) setState(() => _switchingId = null);
  }


  void _openDetail(ChecklistVehicle vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VehicleDetailScreen(controller: _controller, vehicleId: vehicle.id),
      ),
    );
  }

  Future<void> _addVehicle() async {
    final draft = await showDraftSheet<VehicleItemDraft>(
      context,
      (_) => VehicleDraftSheet(vehicleTypes: _controller.vehicleTypes),
    );
    if (draft == null || !mounted) return;
    await _controller.addVehicle(draft);
    _showActionErrorIfAny();
  }

  void _showActionErrorIfAny() {
    if (_controller.actionError != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_controller.actionError!)));
      _controller.clearActionError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: 'Tus vehículos',
            subtitle: 'Toca un vehículo para ver su estado y documentos',
            showBack: true,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final checklist = _controller.checklist;
                if (checklist == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Stack(
                  children: [
                    _content(checklist),
                    if (_controller.savingVehicle)
                      const SavingOverlay(message: 'Registrando tu vehículo…'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(Checklist checklist) {
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          if (!checklist.hasVehicle)
            const ChecklistEmptyLine(
              'Aún no agregaste tu vehículo. Es obligatorio para aprobar tu ingreso.',
            )
          else
            for (final v in checklist.vehicles)
              ChecklistTile(
                icon: Icons.directions_car,
                title: v.label,
                subtitle: v.isPrimary
                    ? '${_vehicleSubtitle(v)} · lo estás usando'
                    : _vehicleSubtitle(v),
                // The choice belongs in the LIST: it is where he sees his
                // vehicles side by side and decides between them. Having it only
                // inside the detail meant nobody found it.
                trailing: v.isPrimary
                    ? const _InUseBadge()
                    : v.approvalStatus == 'approved'
                        ? _UseButton(
                            busy: _switchingId == v.id,
                            onTap: () => _usePrimary(v.id),
                          )
                        : VehicleBadge(status: v.approvalStatus),
                onTap: () => _openDetail(v),
              ),
          if (widget.allowAdd) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _controller.savingVehicle ? null : _addVehicle,
              icon: const Icon(Icons.add, size: 18),
              label: Text(checklist.hasVehicle ? 'Agregar otro vehículo' : 'Agregar vehículo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.fieldBorder),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _vehicleSubtitle(ChecklistVehicle v) {
    final total = v.documents.length;
    final pending = v.documents.where((d) => d.needsAction).length;
    if (total == 0) return 'Sin documentos requeridos por ahora';
    if (pending > 0) return '$pending de $total documentos por resolver';
    return '$total documento${total == 1 ? '' : 's'} · al día';
  }
}
