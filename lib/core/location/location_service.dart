import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import 'location_queue.dart';
import 'location_tracker.dart';

/// What stands between the app and the tracking service.
///
/// Deliberately thin, like `PushService`: it starts, stops and asks for
/// permissions. It does not decide WHO may be tracked — the server does that,
/// and answers with a reason the moment a batch arrives.
class LocationService {
  LocationService({LocationQueue? queue}) : _queue = queue ?? LocationQueue();

  final LocationQueue _queue;

  static const int _serviceId = 512;
  static const String _channelId = 'edv_ubicacion';

  bool _initialised = false;

  /// Enough to track: "while using the app" DOES cover it.
  ///
  /// This is the part that is easy to get wrong. A foreground service of type
  /// `location`, STARTED while the app is in the foreground, counts as
  /// "while-in-use" and keeps receiving positions after the app is closed —
  /// no "all the time" permission involved.
  ///
  /// ACCESS_BACKGROUND_LOCATION only buys one thing here: STARTING the service
  /// from the background, which in practice means reviving it after a reboot
  /// without the driver opening the app. Nice to have, not required — and
  /// Android 11+ does not even offer it in the dialog, only buried in settings.
  Future<bool> canTrack() async {
    if (!Platform.isAndroid) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Whether tracking also survives a reboot on its own.
  Future<bool> hasBackgroundPermission() async {
    if (!Platform.isAndroid) return false;
    return await Geolocator.checkPermission() == LocationPermission.always;
  }

  /// Asks for location. One prompt — the one Android actually shows.
  Future<LocationPermission> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      // The phone's location is switched off entirely: no prompt will fix that.
      return LocationPermission.denied;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      return Geolocator.requestPermission();
    }
    return permission;
  }

  /// Takes the driver straight to the "Permiso de Ubicación" screen.
  ///
  /// Android does NOT let an app open that screen with an intent: the
  /// activity behind it is guarded by GRANT_RUNTIME_PERMISSIONS, a
  /// system-signature permission. The supported way in is to REQUEST the
  /// background permission — from Android 11 the system stops showing an
  /// "Allow all the time" option in the dialog and sends the user to that
  /// settings page instead. So this is a permission request that happens to
  /// land where we want, not a navigation.
  ///
  /// Only meaningful once "while in use" is already granted: geolocator adds
  /// ACCESS_BACKGROUND_LOCATION to the request exactly in that case.
  Future<bool> requestBackgroundPermission() async {
    if (!Platform.isAndroid) return false;
    if (await Geolocator.checkPermission() != LocationPermission.whileInUse) {
      return false;
    }
    final result = await Geolocator.requestPermission();
    return result == LocationPermission.always;
  }

  /// Opens this app's settings page. The fallback: on a phone where the
  /// request above leads nowhere (already denied for good, or a launcher
  /// that skips the screen), the driver still gets somewhere useful.
  Future<void> openSettings() => Geolocator.openAppSettings();

  void _init() {
    if (_initialised) return;
    _initialised = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: _channelId,
        channelName: 'Ubicación en servicio',
        channelDescription: 'Aparece mientras compartes tu ubicación con EDV Route.',
        // The notification is not news, it is a state: it must not buzz on every
        // update.
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Server-configured; this is only the value used until the first reply
        // comes back with the real one.
        eventAction: ForegroundTaskEventAction.repeat(600 * 1000),
        // Only actually fires for drivers who granted "all the time": starting
        // a location service from the background needs it. Harmless otherwise —
        // Android refuses the start and the app restarts tracking on next open.
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> isRunning() => FlutterForegroundTask.isRunningService;

  /// Starts tracking. Safe to call when already running.
  Future<bool> start() async {
    if (!Platform.isAndroid) return false;
    if (!await canTrack()) return false;

    _init();
    if (await FlutterForegroundTask.isRunningService) return true;

    // The result is a sealed type, not a flag: ServiceRequestSuccess, or a
    // failure carrying the reason Android refused (a missing permission, an
    // undeclared service type on Android 14+).
    final result = await FlutterForegroundTask.startService(
      serviceId: _serviceId,
      notificationTitle: 'EDV Route · en servicio',
      // Says what is happening in plain words. Somebody being located has a
      // right to read it at a glance, without opening anything.
      notificationText: 'Compartiendo tu ubicación mientras estás activo',
      notificationIcon: null,
      callback: startLocationTrackerCallback,
    );
    return result is ServiceRequestSuccess;
  }

  /// Stops tracking. The queue is left alone: points already taken while on duty
  /// are still worth sending next time.
  Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /// Logout: stop and forget. The next driver on this phone must not inherit
  /// the previous one's positions — the same reasoning as revoking the push
  /// token.
  Future<void> stopAndClear() async {
    await stop();
    await _queue.clear();
  }
}
