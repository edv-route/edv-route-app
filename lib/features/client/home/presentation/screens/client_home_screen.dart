import 'package:flutter/material.dart';

import '../../../../../domain/entities/client.dart';
import '../../../../../shared/widgets/gradient_header.dart';
import '../../../../../theme/app_colors.dart';

/// Passenger home — a MOCK-UP on purpose (fase C-c): it shows the shape the
/// product will have (destination search, recent trips, quick chips) without
/// pretending any of it works. Everything non-functional says so out loud: the
/// preview banner marks the sample trips, and every dead-end tap answers with
/// the same honest notice. That is the lesson of the old "Beneficios" tile —
/// a button that promises and answers "próximamente" unannounced is worse
/// than no button.
class ClientHomeScreen extends StatelessWidget {
  final Client client;

  const ClientHomeScreen({super.key, required this.client});

  /// The one honest answer of every not-yet-functional control.
  void _notYet(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Muy pronto podrás pedir un viaje desde aquí.'),
      ));
  }

  void _noticesNotYet(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Aquí llegarán tus avisos. Muy pronto.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            children: [
              // The search card mounts OVER the header's bottom edge so it
              // reads as THE action of the screen (approved mock-up). The
              // transform shifts the whole scroll content up; layout-wise the
              // gap simply moves to the end of the list, where it is padding.
              Container(
                transform: Matrix4.translationValues(0, -46, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _searchCard(context),
                    const SizedBox(height: 16),
                    _previewBanner(),
                    const SizedBox(height: 20),
                    _tripsSection(context),
                    const SizedBox(height: 20),
                    _verifiedDriversCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return GradientHeader(
      child: Padding(
        // Extra bottom room for the search card that overlaps this edge.
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Image(image: AssetImage('assets/images/edv_logo_gold.png'), height: 28),
                const Spacer(),
                IconButton(
                  onPressed: () => _noticesNotYet(context),
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 24),
                  tooltip: 'Avisos',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _avatar(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hola,',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        client.firstName.isEmpty ? client.fullName : client.firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.gold,
      foregroundImage: client.photoUrl != null ? NetworkImage(client.photoUrl!) : null,
      child: Text(
        _initials,
        style: const TextStyle(
          color: AppColors.primary950,
          fontWeight: FontWeight.w800,
          fontSize: 19,
        ),
      ),
    );
  }

  String get _initials {
    final parts = client.fullName.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }

  Widget _searchCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _notYet(context),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.primary, size: 20),
                  SizedBox(width: 12),
                  Text(
                    '¿A dónde vas?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _quickChip(context, Icons.home_outlined, 'Casa')),
              const SizedBox(width: 10),
              Expanded(child: _quickChip(context, Icons.work_outline, 'Trabajo')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickChip(BuildContext context, IconData icon, String label) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _notYet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The honest watermark: nothing below works yet, and the screen says so.
  Widget _previewBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gold100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.gold800),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Vista previa. Los viajes de abajo son de ejemplo: todavía no se puede pedir uno.',
              style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.gold800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Expanded(
              child: Text(
                'Tus viajes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ),
            InkWell(
              onTap: () => _notYet(context),
              child: const Text(
                'Ver todos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _exampleTrip('Av. Bolívar Norte', 'Ayer · 4,2 km', r'$3,50'),
        const SizedBox(height: 12),
        _exampleTrip('C.C. Sambil Valencia', 'Lunes · 7,8 km', r'$5,00'),
      ],
    );
  }

  Widget _exampleTrip(String destination, String detail, String amount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.place_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 3),
                Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _verifiedDriversCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.gold100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_user_outlined, color: AppColors.gold800, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choferes verificados',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                SizedBox(height: 4),
                Text(
                  'Todos los afiliados de EDV Route están registrados con sus documentos al día.',
                  style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
