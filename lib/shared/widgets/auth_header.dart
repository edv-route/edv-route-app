import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'gradient_header.dart';

/// Shared header for logo-fronted screens (selection, login, register, dashboard,
/// status). Owns the logo, title/subtitle and a FIXED height so every screen's
/// header lines up. The back button shares the logo's row (so it never adds
/// height), and the content is pinned to the bottom of the block.
class AuthHeader extends StatelessWidget {
  final String title;
  final String? highlight;
  final String? subtitle;
  final bool showBack;

  const AuthHeader({
    super.key,
    required this.title,
    this.highlight,
    this.subtitle,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      height: GradientHeader.kStandardHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Pin the content to the bottom so every header aligns identically.
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Back button shares the logo's row: it never adds to the height.
            Row(
              children: [
                if (showBack) ...[
                  _BackButton(onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 12),
                ],
                const Image(
                  image: AssetImage('assets/images/edv_logo_gold.png'),
                  height: 34,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildTitle(),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    const style = TextStyle(
      color: Colors.white,
      fontSize: 23,
      fontWeight: FontWeight.w800,
      height: 1.15,
    );
    final h = highlight;
    if (h == null || !title.contains(h)) {
      return Text(title, style: style);
    }
    final i = title.indexOf(h);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: title.substring(0, i)),
          TextSpan(text: h, style: const TextStyle(color: AppColors.gold)),
          TextSpan(text: title.substring(i + h.length)),
        ],
      ),
      style: style,
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
