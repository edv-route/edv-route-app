import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// The alta's "Resumen de cobro" card: membership + tariff × weeks + total, with
/// a weeks stepper. Mirrors the panel wizard's step-4 summary so the affiliate
/// sees exactly what will be charged before paying. The weeks control locks once
/// a payment is added (matching the panel), so the amount can't drift away from
/// the captured receipt.
class EnrollmentSummaryCard extends StatelessWidget {
  final String membershipName;
  final double membershipPrice;
  final String tariffName;
  final double tariffPrice;
  final int periods;
  final double total;
  final bool locked;
  final ValueChanged<int> onPeriodsChanged;

  const EnrollmentSummaryCard({
    super.key,
    required this.membershipName,
    required this.membershipPrice,
    required this.tariffName,
    required this.tariffPrice,
    required this.periods,
    required this.total,
    required this.locked,
    required this.onPeriodsChanged,
  });

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.cardGrey,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: const Text(
              'RESUMEN DE COBRO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.muted,
              ),
            ),
          ),
          // Membership (one-off)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        membershipName,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Membresía · pago único',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  _money(membershipPrice),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Tariff + weeks stepper
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Tarifa', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ),
                    Text(
                      '${_money(tariffPrice)} × $periods',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(tariffName, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Semanas',
                      style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    _WeeksStepper(value: periods, enabled: !locked, onChanged: onPeriodsChanged),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  locked
                      ? 'Quita el pago para cambiar las semanas.'
                      : '1 semana = tarifa básica; más = adelanto.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          // Total
          Container(
            color: AppColors.gold50,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total a pagar',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.gold900),
                      ),
                      Text(
                        periods > 1 ? 'Membresía + $periods semanas' : 'Membresía + 1 semana',
                        style: const TextStyle(color: AppColors.gold800, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  _money(total),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gold900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact − N + control for the number of prepaid weeks.
class _WeeksStepper extends StatelessWidget {
  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const _WeeksStepper({required this.value, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(Icons.remove, enabled && value > 1, () => onChanged(value - 1)),
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 15),
            ),
          ),
          _button(Icons.add, enabled, () => onChanged(value + 1)),
        ],
      ),
    );
  }

  Widget _button(IconData icon, bool on, VoidCallback onTap) => InkWell(
        onTap: on ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: on ? AppColors.primary : AppColors.muted),
        ),
      );
}
