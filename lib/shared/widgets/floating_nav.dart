import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// One entry of the floating island nav: an icon and its label.
typedef FloatingNavTab = ({IconData icon, String label});

/// Floating "island" bottom navigation shared by the driver and the client
/// shells: a brand-red rounded pill, detached from the screen edges, with a
/// gold-highlighted active tab (modern-app style). The tabs are the caller's;
/// the look is defined ONCE here so the two modes stay visually identical.
class FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelected;
  final List<FloatingNavTab> tabs;

  const FloatingNav({
    super.key,
    required this.index,
    required this.onSelected,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: tabs[i].icon,
                    label: tabs[i].label,
                    selected: i == index,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const inactive = Colors.white70;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? AppColors.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 20, color: selected ? const Color(0xFF661212) : inactive),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.gold : inactive,
            ),
          ),
        ],
      ),
    );
  }
}
