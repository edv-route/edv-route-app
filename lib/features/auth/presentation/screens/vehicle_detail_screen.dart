import 'package:flutter/material.dart';

import '../../../../shared/widgets/auth_header.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/checklist.dart';
import '../controllers/checklist_controller.dart';
import '../widgets/checklist_widgets.dart';
import 'document_detail_screen.dart';

/// Detail of a single vehicle: its own review state + reason, and its documents as
/// navigable rows into the shared [DocumentDetailScreen]. Re-derives the vehicle
/// from the shared controller's checklist on every rebuild so it stays in sync
/// after any document upload.
class VehicleDetailScreen extends StatelessWidget {
  final ChecklistController controller;
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.controller, required this.vehicleId});

  ChecklistVehicle? _findVehicle(Checklist c) {
    for (final v in c.vehicles) {
      if (v.id == vehicleId) return v;
    }
    return null;
  }

  void _openDocument(BuildContext context, ChecklistDocument doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(
          controller: controller,
          requirementId: doc.requirementId,
          vehicleId: vehicleId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final checklist = controller.checklist;
          final vehicle = checklist == null ? null : _findVehicle(checklist);
          return Column(
            children: [
              AuthHeader(title: vehicle?.label ?? 'Vehículo', showBack: true),
              Expanded(
                child: vehicle == null ? _unavailable() : _detail(context, vehicle),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _unavailable() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Este vehículo ya no está disponible.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ),
      );

  Widget _detail(BuildContext context, ChecklistVehicle vehicle) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        _VehicleStatusHeadline(vehicle: vehicle),
        if (vehicle.isRejected && vehicle.rejectionReason != null) ...[
          const SizedBox(height: 16),
          RejectionReasonBox(reason: vehicle.rejectionReason!),
        ],
        const SizedBox(height: 20),
        const Text(
          'Documentos del vehículo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        if (vehicle.documents.isEmpty)
          const ChecklistEmptyLine('No hay documentos requeridos para este vehículo.')
        else
          for (final d in vehicle.documents)
            ChecklistTile(
              icon: Icons.description_outlined,
              title: d.requirementName + (d.isRequired ? '' : ' (opcional)'),
              trailing: DocBadge(doc: d),
              onTap: () => _openDocument(context, d),
            ),
      ],
    );
  }
}

/// The vehicle's state summary at the top of its detail.
class _VehicleStatusHeadline extends StatelessWidget {
  final ChecklistVehicle vehicle;

  const _VehicleStatusHeadline({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final (icon, color, title) = _describe(vehicle.approvalStatus);
    final plate = vehicle.plate;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
                      ),
                    ),
                    VehicleBadge(status: vehicle.approvalStatus),
                  ],
                ),
                if (plate != null && plate.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Placa: $plate',
                    style: const TextStyle(fontSize: 13.5, color: AppColors.ink, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _describe(String status) {
    switch (status) {
      case 'approved':
        return (Icons.check_circle, const Color(0xFF166534), 'Aprobado');
      case 'rejected':
        return (Icons.cancel, AppColors.primary700, 'Rechazado');
      default:
        return (Icons.hourglass_top, AppColors.gold700, 'En revisión');
    }
  }
}
