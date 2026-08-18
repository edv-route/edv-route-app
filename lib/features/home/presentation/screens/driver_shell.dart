import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/driver.dart';
import './dashboard_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Authenticated driver container: two tabs (Inicio / Perfil) behind a floating
/// "island" bottom nav. Kept to two tabs for now; Historial/Agendados come later.
class DriverShell extends StatefulWidget {
  final Driver driver;

  const DriverShell({super.key, required this.driver});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;

  /// The shell owns the driver so both tabs read the SAME one: editing his data
  /// or his photo in Perfil used to leave Inicio showing the old values, and the
  /// duty switch existed twice with two separate states.
  late Driver _driver = widget.driver;

  void _onDriverChanged(Driver updated) => setState(() => _driver = updated);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(driver: _driver, onDriverChanged: _onDriverChanged),
          ProfileScreen(driver: _driver, onDriverChanged: _onDriverChanged),
        ],
      ),
      bottomNavigationBar: _FloatingNav(
        index: _index,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Floating "island" bottom navigation: a brand-red rounded pill, detached from
/// the screen edges, with a gold-highlighted active tab (modern-app style).
class _FloatingNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelected;

  const _FloatingNav({required this.index, required this.onSelected});

  static const List<({IconData icon, String label})> _tabs = [
    (icon: Icons.home_rounded, label: 'Inicio'),
    (icon: Icons.person_rounded, label: 'Perfil'),
  ];

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
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _tabs[i].icon,
                    label: _tabs[i].label,
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
