import '../../core/location/location_queue.dart';

/// What the server answered to a batch of positions.
class LocationReportResult {
  const LocationReportResult({
    required this.accepted,
    required this.rejected,
    required this.intervalSeconds,
  });

  final int accepted;
  final int rejected;

  /// How often to report from now on. Decided by the SERVER, so the day trips
  /// arrive the pace can be raised from the panel without publishing an APK.
  final int intervalSeconds;
}

/// Sending the driver's positions.
abstract interface class LocationsRepository {
  /// Sends a batch. Throws [LocationNotAllowedException] when this driver may no
  /// longer report — the caller must STOP the service, not retry.
  Future<LocationReportResult> report(List<QueuedPoint> points);
}

/// The server refused because of who the driver is now: suspended, penalized,
/// inactive, tariff not started.
///
/// Distinct from any other failure on purpose: a network error means "try again
/// in ten minutes", this one means "stop waking the GPS at all". Treating them
/// the same drains a battery for a request that will never be accepted.
class LocationNotAllowedException implements Exception {
  const LocationNotAllowedException(this.message);

  /// Written by the server for the driver to read.
  final String message;

  @override
  String toString() => message;
}
