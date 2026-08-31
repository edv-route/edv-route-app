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

  /// Unread notices for the bell. Owned by the shell, like the driver himself
  /// and the duty switch: both tabs must show the SAME number, and a header
  /// that fetched it on its own would show two different bells.
  final int unreadNotifications;

  /// Opens the information screen: benefits, tariff rules, what is expected of
  /// him. Null hides the icon (screens outside the shell).
  final VoidCallback? onInfoTap;

  /// Opens the inbox. Null hides the bell entirely (screens outside the shell).
  final VoidCallback? onNotificationsTap;

  const DriverHeader({
    super.key,
    required this.driver,
    this.onInfoTap,
    required this.available,
    this.onAvailabilityChanged,
    this.savingAvailability = false,
    this.onEdit,
    this.onPhotoTap,
    this.photoBusy = false,
    this.unreadNotifications = 0,
    this.onNotificationsTap,
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
            const SizedBox(height: 12),
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
        if (onNotificationsTap != null) ...[
          _NotificationsBell(unread: unreadNotifications, onTap: onNotificationsTap!),
          if (onEdit != null) const SizedBox(width: 4),
        ],
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

  /// The duty switch. Deliberately SMALL: it is a state indicator he glances at,
  /// not the point of the screen. It hugs its content instead of spanning the
  /// header (a full-width band read as the main element), and the label keeps a
  /// real gap from the switch so they do not look stuck together.
  Widget _dutyStrip() {
    final label = available ? 'Activo' : 'Inactivo';
    final dot = available ? const Color(0xFF22C55E) : const Color(0xFFF97316);
    final pill = Container(
        padding: const EdgeInsets.fromLTRB(12, 2, 6, 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              height: 28,
              width: 38,
              child: FittedBox(
                fit: BoxFit.contain,
                child: savingAvailability
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Switch(
                        value: available,
                        onChanged: onAvailabilityChanged,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF16A34A),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.white30,
                      ),
              ),
            ),
          ],
        ),
    );

    if (onInfoTap == null) return Align(alignment: Alignment.centerLeft, child: pill);

    // Pill on the left, information on the right: the icon sits at the bottom
    // edge of the header, away from the bell, so the two never read as a pair.
    return Row(
      children: [
        pill,
        const Spacer(),
        InkWell(
          onTap: onInfoTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.info_outline,
              size: 22,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }

  String get _initials {
    final parts = driver.fullName.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }
}

/// The bell, with its unread badge.
///
/// It lives in the HEADER and not in the floating island (decisión de Luis): the
/// island navigates between places one *is*, while notices are consulted and
/// closed — and the island's ~3 comfortable slots are needed for Viajes. The
/// header also has one concrete advantage: GOLD is free here. In the island gold
/// already means "active tab", so a gold badge there would say two things at once.
class _NotificationsBell extends StatelessWidget {
  final int unread;
  final VoidCallback onTap;

  const _NotificationsBell({required this.unread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: unread == 0 ? 'Avisos' : 'Avisos, $unread sin leer',
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
              if (unread > 0)
                Positioned(
                  right: -5,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 17),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(9),
                      // The badge sits on a red gradient; without this ring it
                      // reads as a smudge on the bell instead of a count.
                      border: Border.all(color: AppColors.primary900, width: 1.5),
                    ),
                    child: Text(
                      // Past 9 the exact number stops mattering and starts
                      // widening the badge over the logo.
                      unread > 9 ? '9+' : '$unread',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary900,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
