import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../application_progress.dart';

/// Visual pieces of the redesigned "Completa tu solicitud" (2026-11-12).
/// Stateless: the hub screen owns the data and the navigation.

const _okFg = Color(0xFF166534);
const _okBg = Color(0xFFDCFCE7);
const _badFg = Color(0xFF991B1B);
const _badBg = Color(0xFFFEE2E2);
const _waitFg = Color(0xFF92400E);
const _waitBg = Color(0xFFFEF3C7);

({Color fg, Color bg}) _colorsFor(SectionTone tone) => switch (tone) {
      SectionTone.done => (fg: _okFg, bg: _okBg),
      SectionTone.action => (fg: _badFg, bg: _badBg),
      SectionTone.review => (fg: _waitFg, bg: _waitBg),
    };

/// Three segments, one per section; gold when approved.
class ProgressSegments extends StatelessWidget {
  const ProgressSegments({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: i < done ? AppColors.gold500 : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$done de $total secciones aprobadas',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// "SIGUIENTE PASO": the one thing to do now, with its button.
class NextStepCard extends StatelessWidget {
  const NextStepCard({super.key, required this.step, required this.onTap});

  final NextStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1D5D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'SIGUIENTE PASO',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(step.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
          if (step.detail != null && step.detail!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(step.detail!, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.muted)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
            ),
            child: Text(step.action),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the next step when nothing is in his hands.
class WaitingCard extends StatelessWidget {
  const WaitingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_top_rounded, color: _waitFg),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enviaste todo. La oficina está revisando tu solicitud y te avisamos cuando responda.',
              style: TextStyle(fontSize: 13.5, height: 1.45, color: Color(0xFF78350F)),
            ),
          ),
        ],
      ),
    );
  }
}

/// One section of the solicitud: icon, name, what it holds, and its state.
class HubSectionTile extends StatelessWidget {
  const HubSectionTile({
    super.key,
    required this.state,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final SectionState state;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(state.tone);
    final iconColors =
        state.tone == SectionTone.review ? (fg: const Color(0xFF4B5563), bg: const Color(0xFFF3F4F6)) : colors;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x0F111827), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: iconColors.bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColors.fg, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  state.chip,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: colors.fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
