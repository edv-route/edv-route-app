import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../data/repositories/vehicle_draft_store.dart';
import '../../../../domain/entities/vehicle_draft.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/media_picker.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
import '../controllers/vehicle_draft_controller.dart';
import '../widgets/vehicle_draft_form.dart';

/// The vehicle the driver is putting together, all in one screen and all
/// editable, until he decides to send it (2026-08-20).
///
/// Nothing here reaches the server. He can change the plate, retake the photo or
/// swap a paper as many times as he needs; "Enviar a revisión" only lights up
/// when the data, the photo and every document are in place — the same three
/// things the backend demands, so he never gets a rejection he could have seen
/// coming on his own screen.
class VehicleDraftScreen extends StatefulWidget {
  /// Set when correcting a REJECTED vehicle: the draft goes back to that one.
  final String? correctingVehicleId;
  final String? rejectionReason;

  const VehicleDraftScreen({super.key, this.correctingVehicleId, this.rejectionReason});

  @override
  State<VehicleDraftScreen> createState() => _VehicleDraftScreenState();
}

class _VehicleDraftScreenState extends State<VehicleDraftScreen> {
  VehicleDraftController? _controller;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final store = await VehicleDraftStore.open();
    if (!mounted) return;
    final controller = VehicleDraftController(
      store,
      Dependencies.instance.enrollmentRepository,
      Dependencies.instance.catalogsRepository,
    );
    setState(() => _controller = controller);
    await controller.load(correctingVehicleId: widget.correctingVehicleId);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await pickPhoto(context);
    if (image == null || !mounted) return;
    await _controller!.setPhoto(image);
  }

  Future<void> _pickDocument(DraftDocument doc) async {
    final file = await pickDocument(context);
    if (file == null || !mounted) return;
    await _controller!.setDocument(doc.requirementId, file);
  }

  /// The point of no return, said plainly BEFORE it happens: once it is sent he
  /// cannot touch it again unless the admin rejects something.
  Future<void> _confirmAndSend() async {
    final controller = _controller!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Enviar a revisión?'),
        content: const Text(
          'Un administrador revisará tu vehículo y sus documentos.\n\n'
          'Una vez enviado NO podrás editar los datos ni cambiar los documentos, '
          'salvo que te rechacen alguno.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Revisar de nuevo'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, enviar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final sent = await controller.send();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (sent) {
      Navigator.of(context).pop(true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Tu vehículo fue enviado a revisión.')),
        );
    } else if (controller.error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(controller.error!)));
      controller.clearError();
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Descartar el vehículo?'),
        content: const Text('Se borrará lo que llevas cargado en este teléfono.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    await _controller!.discard();
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      body: Column(
        children: [
          AuthHeader(
            title: widget.correctingVehicleId == null ? 'Nuevo vehículo' : 'Corregir vehículo',
            subtitle: 'Nada se envía hasta que toques «Enviar a revisión»',
            showBack: true,
          ),
          Expanded(
            child: controller == null
                ? const Center(child: CircularProgressIndicator())
                : ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => controller.loading
                        ? const Center(child: CircularProgressIndicator())
                        : _body(controller),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _body(VehicleDraftController controller) {
    final draft = controller.draft;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.rejectionReason != null) ...[
            _RejectionNote(reason: widget.rejectionReason!),
            const SizedBox(height: 16),
          ],
          VehicleDraftForm(
            draft: draft,
            vehicleTypes: controller.vehicleTypes,
            onChanged: controller.updateData,
          ),
          const SizedBox(height: 20),
          _PhotoSection(path: draft.photoPath, onPick: _pickPhoto),
          const SizedBox(height: 20),
          const Text(
            'Documentos del vehículo',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          for (final doc in draft.documents) ...[
            _DocumentRow(document: doc, onPick: () => _pickDocument(doc)),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 18),
          // What is still missing, right above the button that waits for it —
          // never a disabled button with no explanation.
          if (!draft.isReadyToSend) ...[
            _PendingList(reasons: draft.pendingReasons),
            const SizedBox(height: 12),
          ],
          PrimaryButton(
            label: 'Enviar a revisión',
            loading: controller.sending,
            onPressed: draft.isReadyToSend ? _confirmAndSend : null,
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: controller.sending ? null : _confirmDiscard,
              style: TextButton.styleFrom(foregroundColor: AppColors.muted),
              child: const Text('Descartar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Why it came back, in his own screen, before he starts fixing it.
class _RejectionNote extends StatelessWidget {
  final String reason;

  const _RejectionNote({required this.reason});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 20, color: AppColors.primary700),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu vehículo fue rechazado',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Motivo: $reason',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.primary900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// The single photo, with its preview. Tapping it replaces it.
class _PhotoSection extends StatelessWidget {
  final String? path;
  final VoidCallback onPick;

  const _PhotoSection({required this.path, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto del vehículo',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.cardGrey,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: path == null ? AppColors.fieldBorder : AppColors.primary200,
              ),
              image: path == null
                  ? null
                  : DecorationImage(image: FileImage(File(path!)), fit: BoxFit.cover),
            ),
            child: path != null
                ? null
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.muted),
                        SizedBox(height: 8),
                        Text(
                          'Toca para agregar la foto',
                          style: TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (path != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Cambiar foto'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary700),
            ),
          ),
      ],
    );
  }
}

/// One document slot: what it is, whether it is attached, and how to attach it.
class _DocumentRow extends StatelessWidget {
  final DraftDocument document;
  final VoidCallback onPick;

  const _DocumentRow({required this.document, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final filled = document.isFilled;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: filled ? AppColors.primary200 : AppColors.cardGrey),
        ),
        child: Row(
          children: [
            Icon(
              filled ? Icons.check_circle : Icons.description_outlined,
              size: 22,
              color: filled ? const Color(0xFF16A34A) : AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.requirementName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    filled ? (document.fileName ?? 'Archivo adjunto') : 'Toca para adjuntar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Text(
              filled ? 'Cambiar' : 'Adjuntar',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The checklist that stands between him and the send button.
class _PendingList extends StatelessWidget {
  final List<String> reasons;

  const _PendingList({required this.reasons});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.gold50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para enviarlo falta:',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.gold900,
              ),
            ),
            const SizedBox(height: 6),
            for (final reason in reasons)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('· ', style: TextStyle(color: AppColors.gold900)),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.gold900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}
