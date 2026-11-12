import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../domain/entities/identity.dart';
import '../../../../domain/entities/picked_image.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';
import '../controllers/identity_flow_controller.dart';
import '../widgets/identity_slot_card.dart';
import 'identity_camera_screen.dart';

/// The three identity photos on one screen. The same screen serves the
/// registration's step 2 (affiliate and passenger), the screen that demands
/// them from someone already registered, and "Tu identidad" from the
/// solicitud — only the words, the button and the way out change.
class IdentityPhotosScreen extends StatefulWidget {
  const IdentityPhotosScreen({
    super.key,
    required this.controller,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.submitLabel,
    required this.onSubmitted,
    this.intro,
    this.notice,
    this.footnote,
    this.showSteps = false,
    this.canGoBack = true,
    this.onLogout,
    this.loadOnStart = false,
  });

  final IdentityFlowController controller;
  final String title;
  final String highlight;
  final String subtitle;
  final String submitLabel;

  /// Runs once everything was sent; decides where the person goes next.
  final void Function(BuildContext context) onSubmitted;

  final String? intro;

  /// Gold box above the photos (the "ahora pedimos…" explanation).
  final String? notice;

  /// Small print under the photos.
  final String? footnote;

  /// "Tus datos ✓ — Tus fotos" (registration only).
  final bool showSteps;

  /// False for the screen that demands the photos: there is nowhere to go
  /// back to. Back is also closed once a registration created the account.
  final bool canGoBack;
  final VoidCallback? onLogout;

  /// Existing account: fetch what the server already holds.
  final bool loadOnStart;

  @override
  State<IdentityPhotosScreen> createState() => _IdentityPhotosScreenState();
}

class _IdentityPhotosScreenState extends State<IdentityPhotosScreen> {
  IdentityFlowController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    if (widget.loadOnStart) _c.load();
  }

  Future<void> _take(IdentityKind kind) async {
    final image = await Navigator.of(context).push<PickedImage>(
      MaterialPageRoute(builder: (_) => IdentityCameraScreen(kind: kind)),
    );
    if (image != null) _c.capture(kind, image);
  }

  Future<void> _submit() async {
    final done = await _c.submit();
    if (done && mounted) widget.onSubmitted(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final canPop = widget.canGoBack && !_c.accountCreated && !_c.submitting;
        return PopScope(
          canPop: canPop,
          child: Scaffold(
            body: Column(
              children: [
                AuthHeader(
                  title: widget.title,
                  highlight: widget.highlight,
                  subtitle: widget.subtitle,
                  showBack: canPop,
                ),
                Expanded(child: _c.loading ? const Center(child: CircularProgressIndicator()) : _body()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body() {
    final needed = _c.stillNeeded.length;
    final nothingToSend = needed == 0 && !_c.canSubmit && !_c.submitting;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        if (widget.showSteps) ...[const _Steps(), const SizedBox(height: 14)],
        if (widget.notice != null) ...[_Notice(text: widget.notice!), const SizedBox(height: 14)],
        if (widget.intro != null) ...[
          Text(widget.intro!, style: const TextStyle(fontSize: 13.5, height: 1.5, color: Color(0xFF374151))),
          const SizedBox(height: 14),
        ],
        for (final kind in IdentityKind.values) ...[
          _slot(kind),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        const Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.muted),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tus fotos solo las ve la oficina de EDV Route.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ],
        ),
        if (widget.footnote != null) ...[
          const SizedBox(height: 10),
          Text(widget.footnote!, style: const TextStyle(fontSize: 12, height: 1.45, color: AppColors.muted)),
        ],
        const SizedBox(height: 28),
        if (_c.error != null) ...[
          Text(
            _c.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
        ],
        if (nothingToSend)
          Text(
            _c.view.status == IdentityStatus.approved
                ? 'Tus fotos ya fueron aprobadas por la oficina.'
                : 'Tus fotos están en revisión. Te avisamos cuando la oficina responda.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
          )
        else ...[
          if (needed > 0) ...[
            Text(
              needed == 1 ? 'Falta 1 foto' : 'Faltan $needed fotos',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
          ],
          PrimaryButton(
            label: widget.submitLabel,
            loading: _c.submitting,
            onPressed: _c.canSubmit ? _submit : null,
          ),
        ],
        if (widget.onLogout != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _c.submitting ? null : widget.onLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Cerrar sesión'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary900),
            ),
          ),
        ],
      ],
    );
  }

  Widget _slot(IdentityKind kind) {
    final state = _c.slotOf(kind);
    final local = _c.capturedFor(kind);
    final photo = _c.view.photos[kind];
    final takeable = state == SlotState.empty || state == SlotState.captured || state == SlotState.rejected;
    return IdentitySlotCard(
      kind: kind,
      state: state,
      localBytes: local == null ? null : Uint8List.fromList(local.bytes),
      remoteUrl: local == null ? photo?.url : null,
      rejectionReason: photo?.rejectionReason,
      onTake: takeable && !_c.submitting ? () => _take(kind) : null,
    );
  }
}

/// "Tus datos ✓ ── 2 Tus fotos".
class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    const ok = Color(0xFF166534);
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: 14, color: ok),
        ),
        const SizedBox(width: 6),
        const Text('Tus datos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ok)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 2, color: const Color(0xFFE5E7EB))),
        const SizedBox(width: 10),
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Text('2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(width: 6),
        const Text(
          'Tus fotos',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.gold50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.gold800, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.gold900)),
          ),
        ],
      ),
    );
  }
}
