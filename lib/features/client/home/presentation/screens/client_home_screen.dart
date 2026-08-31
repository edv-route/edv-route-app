import 'package:flutter/material.dart';

import '../../../../../core/utils/initials.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../../shared/widgets/gradient_header.dart';
import '../../../../../theme/app_colors.dart';
import '../widgets/home_illustrations.dart';

/// Passenger home — the FINAL design (Luis picked "Propuesta 1" on
/// 2026-08-31, Uber-style top search): a one-row brand header, the golden
/// destination card at the TOP with the greeting inside, and everything else
/// is map. The trips card moved to the Viajes tab (which already says it),
/// and «Choferes verificados» lives in a floating shield that opens the trust
/// sheet — one button, one purpose, no extra menu.
///
/// Still an honest mock-up underneath (fase C-c): a single pill over the map
/// says both truths at once — it is a preview, and the real map arrives with
/// the trips module.
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
          child: Stack(
            children: [
              // The map fills everything below the header, down to the island.
              const Positioned.fill(child: CustomPaint(painter: CityMapPainter())),
              // One pill, both truths: preview + the map is an illustration.
              Positioned(
                top: 216,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Text(
                      'Vista previa · el mapa real llega con los viajes',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
              // The golden card at the TOP: the action reads first.
              Positioned(top: 16, left: 20, right: 20, child: _searchCard(context)),
              // «Choferes verificados» lives here now, one tap away.
              Positioned(right: 16, bottom: 20, child: _trustShield(context)),
            ],
          ),
        ),
      ],
    );
  }

  /// Same header anatomy as the profile tab (asked by Luis, 2026-08-31): logo
  /// top-left, the bell where the profile puts «Editar», and below them the
  /// big avatar with the full name — so the two tabs read as one app.
  Widget _header(BuildContext context) {
    return GradientHeader(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
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
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.gold,
                  foregroundImage: client.photoUrl != null ? NetworkImage(client.photoUrl!) : null,
                  child: Text(
                    initialsOf(client.fullName),
                    style: const TextStyle(
                      color: AppColors.primary950,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    client.fullName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The golden card with the greeting folded in (approved mock-up).
  Widget _searchCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDF8E3), AppColors.gold200],
        ),
        border: Border.all(color: AppColors.gold),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -4,
            top: -6,
            child: CustomPaint(size: Size(92, 46), painter: TaxiCarPainter()),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The greeting lives in the header now (beside the avatar), so
              // the card keeps a single job: the destination.
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 100),
                child: Text(
                  '¿A dónde vas?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _notYet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: AppColors.primary, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Escribe tu destino',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _quickChip(context, Icons.home_outlined, 'Casa')),
                  const SizedBox(width: 10),
                  Expanded(child: _quickChip(context, Icons.work_outline, 'Trabajo')),
                ],
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.gold800),
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

  /// The floating shield: opens the trust sheet.
  Widget _trustShield(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _showTrustSheet(context),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.verified_user_outlined, color: AppColors.gold800, size: 22),
        ),
      ),
    );
  }

  /// The trust content, out of the home but one tap away.
  void _showTrustSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Viaja con confianza',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              const Text(
                'EDV Route es la app de Profesionales del Volante, una asociación real de choferes.',
                style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              _trustRow(
                background: AppColors.gold100,
                icon: Icons.verified_user_outlined,
                iconColor: AppColors.gold800,
                title: 'Choferes verificados',
                body: 'Todos los afiliados están registrados con sus documentos al día.',
              ),
              const SizedBox(height: 12),
              _trustRow(
                background: AppColors.primary50,
                icon: Icons.groups_outlined,
                iconColor: AppColors.primary,
                title: 'Un gremio de verdad',
                body: 'Detrás de cada chofer hay una organización que responde.',
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trustRow({
    required Color background,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: iconColor, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: const TextStyle(fontSize: 12, height: 1.45, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
