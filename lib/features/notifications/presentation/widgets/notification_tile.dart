import 'package:flutter/material.dart';

import '../../../../domain/entities/notification_item.dart';
import '../../../../theme/app_colors.dart';

/// One notice in the inbox.
///
/// The text is printed EXACTLY as the backend wrote it. The only thing derived
/// from [NotificationItem.type] here is the icon and its colour: the moment the
/// phone starts composing wording, the inbox and the push begin to disagree.
class NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const NotificationTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final look = lookFor(item.type);
    final unread = item.isUnread;

    return Material(
      color: unread ? AppColors.primary50 : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread ? AppColors.primary200 : AppColors.cardGrey,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: look.background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(look.icon, size: 20, color: look.foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15,
                              // Unread reads as bold. No badge, no dot: the
                              // weight is enough and it does not add clutter to
                              // a list he scans in a hurry.
                              fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relative(item.createdAt),
                          style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon + colours of a notice type. Public because the detail sheet paints the
/// same badge: opening a notice must not look like a different screen.
typedef NoticeLook = ({IconData icon, Color foreground, Color background});

/// Icon and colour per notice type. Money in, money out and verdicts each read
/// differently at a glance, which is what someone scrolling a list actually uses.
///
/// Shared with the detail sheet: opening a notice must not feel like a different
/// screen, so both read the same table.
NoticeLook lookFor(String type) {
  const good = (foreground: Color(0xFF15803D), background: Color(0xFFDCFCE7));
  const bad = (foreground: AppColors.primary700, background: AppColors.primary100);
  const warn = (foreground: Color(0xFF9A6700), background: Color(0xFFFEF3C7));
  const info = (foreground: AppColors.primary900, background: AppColors.cardGrey);

  return switch (type) {
    'payment_approved' ||
    'application_approved' ||
    'document_approved' ||
    'vehicle_approved' ||
    'driver_reactivated' =>
      (icon: Icons.check_circle_outline_rounded, foreground: good.foreground, background: good.background),
    'payment_rejected' ||
    'application_rejected' ||
    'document_rejected' ||
    'vehicle_rejected' =>
      (icon: Icons.cancel_outlined, foreground: bad.foreground, background: bad.background),
    'penalty_applied' =>
      (icon: Icons.block_rounded, foreground: bad.foreground, background: bad.background),
    'debt_overdue' =>
      (icon: Icons.warning_amber_rounded, foreground: warn.foreground, background: warn.background),
    'charge_issued' || 'charge_reminder' =>
      (icon: Icons.receipt_long_rounded, foreground: warn.foreground, background: warn.background),
    'payment_received' =>
      (icon: Icons.hourglass_top_rounded, foreground: info.foreground, background: info.background),
    'tariff_starting' =>
      (icon: Icons.event_available_rounded, foreground: good.foreground, background: good.background),
    _ => (icon: Icons.notifications_rounded, foreground: info.foreground, background: info.background),
  };
}

/// "hace 5 min", "ayer", "12 ago". Short: it sits beside the title and must
/// never push it around.
String _relative(DateTime moment) {
  final diff = DateTime.now().difference(moment);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'ayer';
  if (diff.inDays < 7) return 'hace ${diff.inDays} días';
  return '${moment.day} ${_months[moment.month - 1]}';
}

const _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];
