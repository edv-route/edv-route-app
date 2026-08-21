import 'package:flutter/material.dart';

import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../theme/app_colors.dart';

/// Asks how many weeks the affiliate wants to prepay, then hands the number back.
///
/// It is a step of its own because "adelantar" means nothing without it — the
/// driver has to know what he is about to pay before the payment form asks him
/// for a reference and a receipt.
///
/// What he actually cares about is not the total but UNTIL WHEN he stays covered,
/// so that line sits right above the button. Returns null if he backs out.
Future<int?> pickAdvanceWeeks(
  BuildContext context, {
  required double weeklyTariff,
  DateTime? paidUntil,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AdvanceWeeksSheet(weeklyTariff: weeklyTariff, paidUntil: paidUntil),
  );
}

class _AdvanceWeeksSheet extends StatefulWidget {
  final double weeklyTariff;
  final DateTime? paidUntil;

  const _AdvanceWeeksSheet({required this.weeklyTariff, this.paidUntil});

  @override
  State<_AdvanceWeeksSheet> createState() => _AdvanceWeeksSheetState();
}

class _AdvanceWeeksSheetState extends State<_AdvanceWeeksSheet> {
  int _weeks = 1;

  /// Coverage runs from where it ends today, not from today: prepaying does not
  /// throw away the days he already paid for.
  DateTime get _coveredUntil =>
      (widget.paidUntil ?? DateTime.now()).add(Duration(days: 7 * _weeks));

  double get _total => widget.weeklyTariff * _weeks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '¿Cuántas semanas?',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.muted),
                tooltip: 'Cerrar',
              ),
            ],
          ),
          const SizedBox(height: 4),
          _stepper(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$_weeks × ${formatUsd(widget.weeklyTariff)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
              Text(
                formatUsd(_total),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quedas cubierto hasta',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
              Text(
                formatDisplayDate(_coveredUntil),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF166534),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Continuar al pago',
            onPressed: () => Navigator.of(context).pop(_weeks),
          ),
        ],
      ),
    );
  }

  Widget _stepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _round(
            icon: Icons.remove,
            // One is the floor; no ceiling. Prepaying as many weeks as he wants
            // is a decision already taken — the server only guards against a typo.
            enabled: _weeks > 1,
            filled: false,
            onTap: () => setState(() => _weeks--),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$_weeks',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  _weeks == 1 ? 'semana' : 'semanas',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          _round(
            icon: Icons.add,
            // No product cap: prepaying is free (decision taken long ago). The
            // only ceiling is a technical guard on the server against a typo.
            enabled: true,
            filled: true,
            onTap: () => setState(() => _weeks++),
          ),
        ],
      ),
    );
  }

  Widget _round({
    required IconData icon,
    required bool enabled,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final color = enabled ? AppColors.primary : AppColors.fieldBorder;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled && enabled ? AppColors.primary : Colors.transparent,
          border: Border.all(color: color, width: 1.5),
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled && enabled ? Colors.white : color,
        ),
      ),
    );
  }
}
