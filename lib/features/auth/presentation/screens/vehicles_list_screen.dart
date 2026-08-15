import 'package:flutter/material.dart';

import '../../../../shared/widgets/auth_header.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/registration_drafts.dart';
import '../controllers/checklist_controller.dart';
import '../widgets/checklist_widgets.dart';
import '../widgets/draft_sheet_scaffold.dart';
import '../widgets/vehicle_draft_sheet.dart';
import 'vehicle_detail_screen.dart';

/// The applicant's vehicles, one navigable row each, plus "add vehicle". Tapping a
/// row opens its detail (data + its documents). Shares the hub's controller.
class VehiclesListScreen extends StatefulWidget {
  final ChecklistController controller;

  const VehiclesListScreen({super.key, required this.controller});

  @override
  State<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends State<VehiclesListScreen> {
  ChecklistController get _controller => widget.controller;

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
                subtitle: _vehicleSubtitle(v),
                trailing: VehicleBadge(status: v.approvalStatus),
                onTap: () => _openDetail(v),
              ),
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
