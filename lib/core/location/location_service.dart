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

  /// Whether "location all the time" was granted. Android 10+ asks for it in a
  /// SECOND prompt that sends the user into system settings, and it is the step
  /// most people fall out of — which is why it gets its own screen with an
  /// explanation instead of being fired blind.
  Future<bool> hasBackgroundPermission() async {
    if (!Platform.isAndroid) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  /// Asks for location, then for the background variant. Returns what it got.
  Future<LocationPermission> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      // The phone's location is switched off entirely: no prompt will fix that.
      return LocationPermission.denied;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse) {
      // Second prompt. On Android 11+ this opens system settings rather than a
      // dialog, so the caller must be ready for the user to come back later.
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

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
        // Back up after a reboot or an app update: a driver who restarts his
        // phone mid-shift should not vanish off the map until he notices.
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
    if (!await hasBackgroundPermission()) return false;

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
