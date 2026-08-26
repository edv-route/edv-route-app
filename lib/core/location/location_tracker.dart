import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/repositories/locations_repository_impl.dart';
import '../../domain/repositories/locations_repository.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';
import 'location_queue.dart';

/// The part that actually runs while the app is closed.
///
/// ⚠️ This lives in a SEPARATE ISOLATE from the app. It shares no memory with
/// it: no `Dependencies.instance`, no session held in a widget, nothing the UI
/// put in a variable. Everything it needs it reads from disk — which is why the
/// queue is a file and the token comes out of secure storage on every pass.
///
/// Android kills background work within minutes, so this is driven by a
/// foreground service: the permanent notification is the price of staying
/// alive, and it is also the honest thing to show someone whose position is
/// being recorded.

/// Told to the main isolate so the UI can react (stop the switch, say why).
const String kTrackerStoppedReason = 'tracker_stopped_reason';

@pragma('vm:entry-point')
void startLocationTrackerCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  late final LocationQueue _queue;
  late final LocationsRepository _repository;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _queue = LocationQueue();
    _repository = LocationsRepositoryImpl(ApiClient(), TokenStorage());
    // Report immediately instead of waiting a full interval: the driver just
    // went on duty and the map should not show him missing for ten minutes.
    await _tick();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Fire and forget: the handler is not async, and a slow network must not
    // block the next tick.
    _tick();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  Future<void> _tick() async {
    await _capture();
    await _flush();
  }

  /// Takes one position and queues it. Queued even when there IS signal: the
  /// send happens right after, and going through the queue means a failure
  /// mid-flight leaves the point safe instead of lost.
  Future<void> _capture() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          // A fix that takes longer than this is not worth the battery: the next
          // pass is only minutes away.
          timeLimit: Duration(seconds: 45),
        ),
      );
      await _queue.add(
        QueuedPoint(
          lat: position.latitude,
          lon: position.longitude,
          accuracyM: position.accuracy,
          recordedAt: position.timestamp,
        ),
      );
    } catch (_) {
      // No fix (indoors, GPS off, timeout). Nothing to do but wait for the next
      // pass — the queue keeps whatever was already there.
    }
  }

  /// Sends everything waiting. On success the sent points are dropped BY COUNT,
  /// so a point captured mid-flight is not thrown away with them.
  Future<void> _flush() async {
    final pending = await _queue.all();
    if (pending.isEmpty) return;

    try {
      final result = await _repository.report(pending);
      await _queue.removeFirst(pending.length);

      // The server decides the pace. Applying it here is what lets the office
      // raise the frequency for every phone at once, without a new APK.
      _applyInterval(result.intervalSeconds);
    } on LocationNotAllowedException catch (e) {
      // Not a network problem: this driver may no longer report. Stop the
      // service rather than wake the GPS every few minutes for a request that
      // will keep being refused.
      await _queue.clear();
      FlutterForegroundTask.sendDataToMain('$kTrackerStoppedReason:${e.message}');
      await FlutterForegroundTask.stopService();
    } catch (_) {
      // Network trouble: keep the points and try again next pass. That IS the
      // queue's whole purpose.
    }
  }

  int? _appliedInterval;

  void _applyInterval(int seconds) {
    if (_appliedInterval == seconds) return;
    _appliedInterval = seconds;
    FlutterForegroundTask.updateService(
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(seconds * 1000),
      ),
    );
  }
}
