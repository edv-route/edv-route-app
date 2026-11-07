/// Runtime configuration.
///
/// The API base URL defaults to **production** (Railway). Override it per run:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1   (Android emulator)
///   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1  (desktop/web)
abstract final class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Moved to a third, paid Railway account on 2026-11-07, which reclaimed the
    // original name: the `-production` suffix of 2026-08-26 is gone. Installed
    // builds that still carry the old URL stop working until updated.
    defaultValue: 'https://edv-route-backend.up.railway.app/api/v1',
  );
}
