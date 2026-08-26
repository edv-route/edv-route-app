import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../core/location/location_service.dart';
import '../../../location/presentation/screens/location_permission_screen.dart';
import '../../../../core/push/push_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../../domain/entities/account_status.dart';
import '../../../../domain/entities/driver.dart';
import '../../../../shared/widgets/notice_banner.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
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

  /// The shell owns the account standing for the same reason it owns the driver:
  /// both tabs render a header from it, and two independent loads would show two
  /// different bells. It also spares the home its own call for the start notice.
  AccountStatus? _account;

  @override
  void initState() {
    super.initState();
    _loadAccount();
    // A notice that lands while he is using the app draws NOTHING by itself
    // (Android only renders push in the background). The shell owns the bell, so
    // it is the one that has to react: refresh the count and say it out loud.
    PushService.instance.arrived.addListener(_onPushArrived);
    PushService.instance.openRequested.addListener(_onOpenRequested);
    // A notification tapped with the app CLOSED sets the flag before this shell
    // exists, so the tap has to be collected on mount or it is lost.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onOpenRequested());
    // Already on duty when the app was last closed: the service may have been
    // killed since (reboot, battery manager), so it is restarted here rather
    // than waiting for him to toggle the switch off and on.
    // Restart only if the permission is already there: on mount he is not
    // making a decision, and a permission screen out of nowhere is intrusive.
    if (_driver.isAvailable) _resumeTrackingIfAllowed();
  }

  @override
  void dispose() {
    PushService.instance.arrived.removeListener(_onPushArrived);
    PushService.instance.openRequested.removeListener(_onOpenRequested);
    super.dispose();
  }

  void _onPushArrived() {
    final notice = PushService.instance.arrived.value;
    if (notice == null || !mounted) return;
    _loadAccount(); // the bell must move the moment the notice arrives
    // A branded card dropping from the top, not a grey slab at the bottom:
    // with the app open THIS is the notification as far as the driver is
    // concerned, so it has to look like one.
    showNoticeBanner(
      context,
      title: notice.title,
      body: notice.body,
      onTap: _openNotifications,
    );
  }

  /// He tapped a notification on the phone: open the inbox.
  void _onOpenRequested() {
    if (!mounted) return;
    if (!PushService.instance.takePendingOpen()) return;
    _openNotifications();
  }

  /// Quiet on purpose: this feeds a badge and an informative banner. Failing
  /// loudly over something the driver cannot act on would be noise.
  Future<void> _loadAccount() async {
    try {
      final account = await Dependencies.instance.accountRepository.loadAccount();
      if (mounted) setState(() => _account = account);
    } catch (_) {
      // Leaves the bell at zero and the banner hidden.
    }
  }

  void _onDriverChanged(Driver updated) {
    final wasAvailable = _driver.isAvailable;
    setState(() => _driver = updated);
    // Going on duty starts reporting, going off stops it. The shell is the only
    // place that sees this change from BOTH tabs, so putting it anywhere else
    // would mean two copies that drift.
    if (updated.isAvailable != wasAvailable) _syncTracking(updated.isAvailable);
  }

  /// Starts or stops location reporting to match the duty switch.
  ///
  /// Failing to start is SILENT for the driver: the usual cause is the
  /// "all the time" permission not being granted, and the place to explain that
  /// is the permission screen — not a error toast every time he goes on duty.
  Future<void> _syncTracking(bool available) async {
    final service = LocationService();
    try {
      if (!available) return service.stop();

      // Asked for the first time HERE, when it is first needed. Asking at login
      // would be asking before he has any reason to say yes, and a denied prompt
      // does not come back.
      //
      // `canTrack`, NOT the background permission: a foreground service started
      // while the app is open keeps reporting after it closes. Demanding
      // "todo el tiempo" would block on a step Android 11+ hides in settings.
      if (!await service.canTrack()) {
        if (!mounted) return;
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => const LocationPermissionScreen()),
        );
        // The screen starts tracking itself when it gets the permission; if it
        // did not, he chose "ahora no" and stays on duty without reporting.
        return;
      }
      await service.start();
    } catch (_) {
      // Tracking must never be what breaks the switch.
    }
  }

  /// Brings tracking back on launch for a driver who was already on duty — the
  /// service may have been killed by a reboot or a battery manager. Silent by
  /// design: if the permission is gone, the next time he flips the switch is
  /// when it gets explained.
  Future<void> _resumeTrackingIfAllowed() async {
    try {
      final service = LocationService();
      if (await service.canTrack()) await service.start();
    } catch (_) {
      // Never let this break the launch.
    }
  }

  /// Opens the inbox and takes the resulting count back from the pop. Refreshing
  /// the whole account here would be a second round trip for a number the screen
  /// he just closed already knows.
  /// The inbox is already on screen. Tapping a second notification (or the bell
  /// behind it) must not stack another copy of it.
  bool _inboxOpen = false;

  Future<void> _openNotifications() async {
    if (_inboxOpen) return;
    _inboxOpen = true;
    final unread = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _inboxOpen = false;
    if (unread == null || !mounted) return;
    setState(() => _account = _account?.withUnread(unread));
  }

  @override
  Widget build(BuildContext context) {
    final unread = _account?.unreadNotifications ?? 0;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            driver: _driver,
            onDriverChanged: _onDriverChanged,
            account: _account,
            unreadNotifications: unread,
            onNotificationsTap: _openNotifications,
          ),
          ProfileScreen(
            driver: _driver,
            onDriverChanged: _onDriverChanged,
            unreadNotifications: unread,
            onNotificationsTap: _openNotifications,
          ),
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
