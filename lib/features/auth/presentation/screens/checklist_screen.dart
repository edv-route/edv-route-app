import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/checklist.dart';
import '../controllers/checklist_controller.dart';

/// "Completa tu solicitud" — after registering (or logging in as an applicant),
/// the driver sees which documents/vehicle are missing, under review, approved or
/// rejected, so he can finish. This first version is read-only (status + guidance);
/// the upload actions (/me/documents, /me/vehicles) are wired next.
class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late final ChecklistController _controller =
      ChecklistController(Dependencies.instance.registrationRepository);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await Dependencies.instance.tokenStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.selection, (_) => false);
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
                  return _ErrorState(message: _controller.error!, onRetry: _controller.load);
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
      onRefresh: _controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          _StatusBanner(checklist: checklist),
          const SizedBox(height: 20),
          const _SectionTitle('Tus documentos'),
          const SizedBox(height: 8),
          if (checklist.driverDocuments.isEmpty)
            const _EmptyLine('No hay documentos requeridos.')
          else
            for (final d in checklist.driverDocuments) _DocRow(doc: d),
          const SizedBox(height: 20),
          const _SectionTitle('Tu vehículo'),
          const SizedBox(height: 8),
          if (!checklist.hasVehicle)
            const _EmptyLine('Aún no agregaste tu vehículo. Es obligatorio para aprobar tu ingreso.')
          else
            for (final v in checklist.vehicles) _VehicleCard(vehicle: v),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold300),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.construction, color: AppColors.gold700, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Las opciones para subir tus documentos y registrar tu vehículo '
                    'llegan en la próxima actualización.',
                    style: TextStyle(fontSize: 13, color: AppColors.ink, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
}

/// Top banner summarizing whether the solicitud is complete or what remains.
class _StatusBanner extends StatelessWidget {
  final Checklist checklist;

  const _StatusBanner({required this.checklist});

  @override
  Widget build(BuildContext context) {
    final ready = checklist.isReadyForReview;
    final n = checklist.pendingActions;
    final color = ready ? AppColors.gold700 : AppColors.primary700;
    final bg = ready ? AppColors.gold50 : AppColors.primary50;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ready ? AppColors.gold300 : AppColors.primary100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ready ? Icons.hourglass_top : Icons.checklist_rtl, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'Tu solicitud está completa' : 'Te falta completar tu solicitud',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  ready
                      ? 'Un administrador la revisará y te avisaremos.'
                      : 'Tienes $n ${n == 1 ? 'punto' : 'puntos'} por resolver antes de la revisión.',
                  style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
      );
}

class _EmptyLine extends StatelessWidget {
  final String text;

  const _EmptyLine(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text, style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.35)),
      );
}

/// A driver-document row: name + review badge + rejection reason when rejected.
class _DocRow extends StatelessWidget {
  final ChecklistDocument doc;

  const _DocRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  doc.requirementName + (doc.isRequired ? '' : ' (opcional)'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              _ReviewBadge(review: doc.review, isRequired: doc.isRequired),
            ],
          ),
          if (doc.isRejected && doc.rejectionReason != null) ...[
            const SizedBox(height: 6),
            Text(
              'Motivo: ${doc.rejectionReason}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.primary700, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

/// A vehicle card: label + its own review state + its document rows.
class _VehicleCard extends StatelessWidget {
  final ChecklistVehicle vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, color: AppColors.muted, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vehicle.label,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              _VehicleBadge(status: vehicle.approvalStatus),
            ],
          ),
          if (vehicle.isRejected && vehicle.rejectionReason != null) ...[
            const SizedBox(height: 6),
            Text(
              'Motivo: ${vehicle.rejectionReason}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.primary700, height: 1.3),
            ),
          ],
          if (vehicle.documents.isNotEmpty) ...[
            const Divider(height: 18),
            for (final d in vehicle.documents) _DocRow(doc: d),
          ],
        ],
      ),
    );
  }
}

/// Colored pill for a document's review state.
class _ReviewBadge extends StatelessWidget {
  final DocReview review;
  final bool isRequired;

  const _ReviewBadge({required this.review, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (review) {
      case DocReview.approved:
        label = 'Aprobado';
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
      case DocReview.pending:
        label = 'En revisión';
        bg = AppColors.gold100;
        fg = AppColors.gold800;
      case DocReview.rejected:
        label = 'Rechazado';
        bg = AppColors.primary100;
        fg = AppColors.primary800;
      case DocReview.missing:
        label = isRequired ? 'Falta' : 'Opcional';
        bg = isRequired ? AppColors.primary50 : AppColors.cardGrey;
        fg = isRequired ? AppColors.primary700 : AppColors.muted;
    }
    return _Pill(label: label, bg: bg, fg: fg);
  }
}

/// Colored pill for a vehicle's review state.
class _VehicleBadge extends StatelessWidget {
  final String status; // pending | approved | rejected

  const _VehicleBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'approved':
        return const _Pill(label: 'Aprobado', bg: Color(0xFFDCFCE7), fg: Color(0xFF166534));
      case 'rejected':
        return const _Pill(label: 'Rechazado', bg: AppColors.primary100, fg: AppColors.primary800);
      default:
        return const _Pill(label: 'En revisión', bg: AppColors.gold100, fg: AppColors.gold800);
    }
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg),
        ),
      );
}

/// Load-failure state with a retry.
class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.muted, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
