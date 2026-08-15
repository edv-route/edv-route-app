import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/checklist.dart';

/// Shared building blocks for the "completa tu solicitud" flow (hub + lists +
/// detail screens). Extracted so the status pills, badges, section cards and
/// navigable rows are defined once and reused across every screen.

// Approved green isn't part of the brand scale, so it lives here as the single
// source of truth for the "aprobado" pills.
const Color _approvedBg = Color(0xFFDCFCE7);
const Color _approvedFg = Color(0xFF166534);

/// Colored pill for a state label.
class StatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const StatusPill({super.key, required this.label, required this.bg, required this.fg});

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

/// Pill for a document's review state (or "Sin archivo" when the slot exists but
/// no file has been attached yet).
class DocBadge extends StatelessWidget {
  final ChecklistDocument doc;

  const DocBadge({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    if (doc.isApproved) {
      return const StatusPill(label: 'Aprobado', bg: _approvedBg, fg: _approvedFg);
    }
    if (doc.isRejected) {
      return const StatusPill(label: 'Rechazado', bg: AppColors.primary100, fg: AppColors.primary800);
    }
    if (doc.isMissing) {
      return StatusPill(
        label: doc.isRequired ? 'Falta' : 'Opcional',
        bg: doc.isRequired ? AppColors.primary50 : AppColors.cardGrey,
        fg: doc.isRequired ? AppColors.primary700 : AppColors.muted,
      );
    }
    if (doc.needsFile) {
      return const StatusPill(label: 'Sin archivo', bg: AppColors.primary50, fg: AppColors.primary700);
    }
    return const StatusPill(label: 'En revisión', bg: AppColors.gold100, fg: AppColors.gold800);
  }
}

/// Pill for a vehicle's review state.
class VehicleBadge extends StatelessWidget {
  final String status; // pending | approved | rejected

  const VehicleBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'approved':
        return const StatusPill(label: 'Aprobado', bg: _approvedBg, fg: _approvedFg);
      case 'rejected':
        return const StatusPill(label: 'Rechazado', bg: AppColors.primary100, fg: AppColors.primary800);
      default:
        return const StatusPill(label: 'En revisión', bg: AppColors.gold100, fg: AppColors.gold800);
    }
  }
}

/// A large tappable card for the hub, one per section (Documentos / Vehículos).
/// Shows an icon, title, a progress subtitle and a red attention dot when the
/// section still needs the applicant to act.
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool needsAttention;
  final VoidCallback onTap;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.needsAttention,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardGrey),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.3),
                    ),
                  ],
                ),
              ),
              if (needsAttention) ...[
                const _AttentionDot(),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionDot extends StatelessWidget {
  const _AttentionDot();

  @override
  Widget build(BuildContext context) => Container(
        height: 9,
        width: 9,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      );
}

/// A navigable row for a document (or vehicle) in a list: title, optional
/// subtitle, a trailing status badge and a chevron. Non-blocking: it only
/// navigates; the action (upload/replace) lives in the detail screen.
class ChecklistTile extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const ChecklistTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.muted, size: 20),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top banner summarizing whether the solicitud is complete or what remains.
class ChecklistStatusBanner extends StatelessWidget {
  final Checklist checklist;

  const ChecklistStatusBanner({super.key, required this.checklist});

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

/// Full-cover progress veil while a blocking action runs (e.g. registering a
/// vehicle and uploading its photos).
class SavingOverlay extends StatelessWidget {
  final String message;

  const SavingOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xCCFFFFFF),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Load-failure state with a retry.
class ChecklistErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const ChecklistErrorState({super.key, required this.message, required this.onRetry});

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

/// Highlighted box showing the admin's rejection reason (shared by document and
/// vehicle detail screens).
class RejectionReasonBox extends StatelessWidget {
  final String reason;

  const RejectionReasonBox({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Motivo del rechazo',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary800),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            style: const TextStyle(fontSize: 13.5, color: AppColors.ink, height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// An empty/hint line in a list.
class ChecklistEmptyLine extends StatelessWidget {
  final String text;

  const ChecklistEmptyLine(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.35),
        ),
      );
}
