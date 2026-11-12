import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../domain/entities/identity.dart';
import '../../../../theme/app_colors.dart';
import '../controllers/identity_flow_controller.dart';

/// One identity photo slot: empty, captured on the phone, or as the office
/// left it (in review, approved, rejected with its reason).
class IdentitySlotCard extends StatelessWidget {
  const IdentitySlotCard({
    super.key,
    required this.kind,
    required this.state,
    this.localBytes,
    this.remoteUrl,
    this.rejectionReason,
    this.onTake,
  });

  final IdentityKind kind;
  final SlotState state;
  final Uint8List? localBytes;
  final String? remoteUrl;
  final String? rejectionReason;

  /// Opens the camera. Null when the slot is final (in review or approved).
  final VoidCallback? onTake;

  static const _okFg = Color(0xFF166534);
  static const _okBg = Color(0xFFDCFCE7);
  static const _badFg = Color(0xFF991B1B);
  static const _badBg = Color(0xFFFEE2E2);
  static const _waitFg = Color(0xFF92400E);
  static const _waitBg = Color(0xFFFEF3C7);

  String get _hint => switch (kind) {
        IdentityKind.selfie => 'Cámara frontal · de frente, sin lentes ni gorra',
        IdentityKind.idFront => 'El lado con tu foto y tus datos',
        IdentityKind.idBack => 'El lado de atrás, completo',
      };

  @override
  Widget build(BuildContext context) {
    final rejected = state == SlotState.rejected;
    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rejected ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB),
          width: rejected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _thumbnail(),
              const SizedBox(width: 14),
              Expanded(child: _texts()),
              _trailing(),
            ],
          ),
          if (rejected) ...[
            const SizedBox(height: 12),
            _reasonBox(),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onTake,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Tomar de nuevo'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );

    // An empty slot is one big target: the whole card opens the camera.
    if (state == SlotState.empty && onTake != null) {
      return Semantics(
        button: true,
        label: 'Tomar ${kind.label}',
        child: InkWell(onTap: onTake, borderRadius: BorderRadius.circular(16), child: card),
      );
    }
    return card;
  }

  Widget _thumbnail() {
    final Widget? image = localBytes != null
        ? Image.memory(localBytes!, fit: BoxFit.cover)
        : remoteUrl != null
            ? Image.network(remoteUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _placeholderIcon())
            : null;
    if (image == null) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder, width: 1.5),
        ),
        child: _placeholderIcon(),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 60,
        height: 60,
        child: Opacity(opacity: state == SlotState.rejected ? 0.6 : 1, child: image),
      ),
    );
  }

  Widget _placeholderIcon() => Icon(
        kind == IdentityKind.selfie ? Icons.person_outline_rounded : Icons.badge_outlined,
        color: AppColors.muted,
        size: 28,
      );

  Widget _texts() {
    final chip = switch (state) {
      SlotState.empty => null,
      SlotState.captured => _chip('Lista', Icons.check_rounded, _okFg, _okBg),
      SlotState.inReview => _chip('En revisión', Icons.schedule_rounded, _waitFg, _waitBg),
      SlotState.approved => _chip('Aprobada', Icons.check_rounded, _okFg, _okBg),
      SlotState.rejected => _chip('Rechazada', Icons.close_rounded, _badFg, _badBg),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kind.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 4),
        chip ?? Text(_hint, style: const TextStyle(fontSize: 12.5, height: 1.35, color: AppColors.muted)),
      ],
    );
  }

  Widget _trailing() {
    if (state == SlotState.empty && onTake != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(10)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_outlined, size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Text('Tomar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ],
        ),
      );
    }
    if (state == SlotState.captured && onTake != null) {
      return TextButton(
        onPressed: onTake,
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        child: const Text('Repetir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _reasonBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MOTIVO DE LA OFICINA',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: _badFg),
          ),
          const SizedBox(height: 4),
          Text(
            rejectionReason ?? 'La oficina pidió que la tomes de nuevo.',
            style: const TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF7F1D1D)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      );
}
