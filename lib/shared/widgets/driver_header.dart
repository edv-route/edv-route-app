import 'package:flutter/material.dart';

import '../../domain/entities/driver.dart';
import '../../theme/app_colors.dart';
import './gradient_header.dart';

/// The affiliate's header, shared by Inicio and Perfil so both look like the
/// same app. It carries his identity and his duty switch, which is the one
/// control he touches every day.
///
/// The layout gives the NAME the whole width — before, the edit button sat
/// beside it and a normal Venezuelan full name came out truncated ("Luis David
/// Villegas…"). The action moved up next to the logo, where it costs no width.
class DriverHeader extends StatelessWidget {
  final Driver driver;

  /// Duty state shown by the switch. Kept outside so both tabs read the same one.
  final bool available;

  /// Null makes the switch read-only (no screen does that today; kept explicit).
  final ValueChanged<bool>? onAvailabilityChanged;

  /// While the change travels to the backend the switch is frozen.
  final bool savingAvailability;

  /// Shown as a pencil + "Editar" when the screen offers editing (Perfil).
  final VoidCallback? onEdit;

  /// Tapping the avatar replaces the photo (Perfil).
  final VoidCallback? onPhotoTap;
  final bool photoBusy;

  const DriverHeader({
    super.key,
    required this.driver,
    required this.available,
    this.onAvailabilityChanged,
    this.savingAvailability = false,
    this.onEdit,
    this.onPhotoTap,
    this.photoBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _logoRow(),
            const SizedBox(height: 14),
            _identityRow(),
            const SizedBox(height: 14),
            _dutyStrip(),
          ],
        ),
      ),
    );
  }

  /// Logo on the left, the screen's action on the right: the action never eats
  /// into the name's width.
  Widget _logoRow() {
    return Row(
      children: [
        const Image(image: AssetImage('assets/images/edv_logo_gold.png'), height: 28),
        const Spacer(),
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
            label: const Text(
              'Editar',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: Colors.white24,
              shape: const StadiumBorder(),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  Widget _identityRow() {
    final rating = driver.avgRating;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _avatar(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Two lines: a full Venezuelan name rarely fits in one.
              Text(
                driver.fullName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    driver.nationalId ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                  if (rating != null) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.star, color: AppColors.gold, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatar() {
    final avatar = CircleAvatar(
      radius: 28,
      backgroundColor: Colors.white,
      foregroundImage: driver.photoUrl != null ? NetworkImage(driver.photoUrl!) : null,
      child: Text(
        _initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 19,
        ),
      ),
    );
    if (onPhotoTap == null) return avatar;
    return GestureDetector(
      onTap: photoBusy ? null : onPhotoTap,
      child: Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.gold400,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: photoBusy
                  ? const SizedBox(
                      height: 11,
                      width: 11,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary900),
                    )
                  : const Icon(Icons.photo_camera, size: 11, color: AppColors.primary900),
            ),
          ),
        ],
      ),
    );
  }

  /// The duty switch, named in words. A coloured dot alone was ambiguous: the
  /// driver could not tell whether green meant "you are active" or "tap to
  /// activate".
  Widget _dutyStrip() {
    final label = available ? 'Activo' : 'Inactivo';
    final dot = available ? const Color(0xFF22C55E) : const Color(0xFFF97316);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            available ? 'Recibiendo viajes' : 'Sin recibir viajes',
            style: const TextStyle(color: Colors.white70, fontSize: 11.5),
          ),
          SizedBox(
            width: 52,
            child: savingAvailability
                ? const Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : Switch(
                    value: available,
                    onChanged: onAvailabilityChanged,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF16A34A),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.white30,
                  ),
          ),
        ],
      ),
    );
  }

  String get _initials {
    final parts = driver.fullName.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }
}
