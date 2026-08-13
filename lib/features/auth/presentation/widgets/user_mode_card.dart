import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Selectable card for the user-type selection screen. Shows a two-tone title
/// ("Modo" + the mode name), a short description and either a chevron (enabled)
/// or a "Próximamente" badge (disabled). Tapping an enabled card fires [onTap].
class UserModeCard extends StatelessWidget {
  final String modePrefix;
  final String modeName;
  final String description;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const UserModeCard({
    super.key,
    required this.modePrefix,
    required this.modeName,
    required this.description,
    required this.icon,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.65,
      child: Material(
        color: AppColors.cardGrey,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$modePrefix ',
                              style: const TextStyle(color: AppColors.primary),
                            ),
                            TextSpan(
                              text: modeName,
                              style: const TextStyle(color: AppColors.ink),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                enabled
                    ? const Icon(Icons.chevron_right, color: AppColors.muted)
                    : const _ComingSoonBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Próximamente',
        style: TextStyle(
          color: AppColors.primary900,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
