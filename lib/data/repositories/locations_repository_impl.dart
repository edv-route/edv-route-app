import '../../core/location/location_queue.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/repositories/locations_repository.dart';

/// Posts batches to `/driver-auth/me/locations`.
///
/// It reads the token from storage on every call rather than being handed one,
/// because the tracking runs in a SEPARATE ISOLATE from the app: there is no
/// shared session object over there, only what is on disk.
class LocationsRepositoryImpl implements LocationsRepository {
  LocationsRepositoryImpl(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  @override
  Future<LocationReportResult> report(List<QueuedPoint> points) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      // No session: there is nobody to report for. Same shape as a refusal so
      // the caller shuts the service down instead of retrying forever.
      throw const LocationNotAllowedException('No hay sesión activa');
    }

    try {
      final res = await _client.post(
        '/driver-auth/me/locations',
        {'points': points.map((p) => p.toJson()).toList()},
        token: token,
      );
      return LocationReportResult(
        accepted: (res['accepted'] as num?)?.toInt() ?? 0,
        rejected: (res['rejected'] as num?)?.toInt() ?? 0,
        intervalSeconds: (res['intervalSeconds'] as num?)?.toInt() ?? 600,
      );
    } on ApiException catch (e) {
      // 403 = this driver may no longer report (suspended, penalized, inactive,
      // tariff not started). 401 = the session is gone. Both mean STOP, and the
      // server's own wording is what the driver sees.
      if (e.statusCode == 403 || e.statusCode == 401) {
        throw LocationNotAllowedException(e.message);
      }
      rethrow;
    }
  }
}
