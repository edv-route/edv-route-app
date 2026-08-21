import 'package:flutter/material.dart';

import '../../../../domain/entities/notification_item.dart';
import '../../../../theme/app_colors.dart';
import 'notification_tile.dart' show NoticeLook, lookFor;

/// One notice OPENED, the way a message is opened: the whole text, unhurried,
/// with the facts that matter pulled out underneath.
///
/// The list can only ever show a summary; this is where the driver actually
/// reads what happened to him — the reason his payment was turned down, the
/// amount, the week involved. Tapping a row used to do nothing but mark it read,
/// which made the inbox feel like a wall of text nobody could act on.
Future<void> showNotificationDetail(BuildContext context, NotificationItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NotificationDetailSheet(item: item),
  );
}

class _NotificationDetailSheet extends StatelessWidget {
  final NotificationItem item;

  const _NotificationDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final look = lookFor(item.type);
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(look),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fullMoment(item.createdAt),
                    style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  // The body in full. No maxLines, no ellipsis: this screen
                  // exists precisely so nothing gets cut.
                  Text(
                    item.body,
                    style: const TextStyle(
                      fontSize: 15.5,
                      color: AppColors.ink,
                      height: 1.55,
                    ),
                  ),
                  ..._details(),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + MediaQuery.of(context).padding.bottom),
            child: SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Brand gradient with the type's icon floating on it — the same colour code
  /// the list uses, so opening a notice never feels like a different screen.
  Widget _header(NoticeLook look) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: look.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(look.icon, size: 30, color: look.foreground),
          ),
        ],
      ),
    );
  }

  /// The facts worth repeating apart from the sentence: the rejection reason
  /// above all, which is what he has to act on.
  List<Widget> _details() {
    final rows = <(String, String)>[];
    final payload = item.payload;

    final amount = payload['amountUsd'];
    if (amount != null) rows.add(('Monto', _money(amount)));

    final fine = payload['fineUsd'];
    if (fine != null) rows.add(('Multa', _money(fine)));

    final weeks = payload['weeksOwed'];
    if (weeks != null) rows.add(('Semanas que debes', '$weeks'));

    final week = payload['weekStart'];
    if (week is String) {
      final parsed = DateTime.tryParse(week);
      if (parsed != null) rows.add(('Semana', _shortDate(parsed.toLocal())));
    }
    final starts = payload['startsAt'];
    if (starts is String) {
      final parsed = DateTime.tryParse(starts);
      if (parsed != null) rows.add(('Fecha de inicio', _shortDate(parsed.toLocal())));
    }

    final reason = payload['reason'];
    final hasReason = reason is String && reason.trim().isNotEmpty;

    if (rows.isEmpty && !hasReason) return const [];

    return [
      const SizedBox(height: 22),
      if (hasReason) ...[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Motivo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                reason.trim(),
                style: const TextStyle(fontSize: 14.5, color: AppColors.ink, height: 1.45),
              ),
            ],
          ),
        ),
        if (rows.isNotEmpty) const SizedBox(height: 14),
      ],
      for (final row in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  row.$1,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
                ),
              ),
              Text(
                row.$2,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

String _money(Object value) {
  final number = value is num ? value.toDouble() : double.tryParse('$value');
  if (number == null) return '$value';
  return '\$${number.toStringAsFixed(2).replaceAll('.', ',')}';
}

const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const _weekdays = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
];

String _shortDate(DateTime d) => '${d.day} de ${_months[d.month - 1]}';

/// "viernes 21 de agosto · 5:56 p. m." — the full moment, because the list only
/// had room for "hace 2 h".
String _fullMoment(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final suffix = d.hour < 12 ? 'a. m.' : 'p. m.';
  return '${_weekdays[d.weekday - 1]} ${_shortDate(d)} · $hour12:$minute $suffix';
}
