/// Runtime configuration.
///
/// The API base URL defaults to **production** (Railway). Override it per run:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1   (Android emulator)
///   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1  (desktop/web)
abstract final class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Moved to the new Railway account on 2026-08-26; the `-production` suffix
    // is what Railway generated when the old name was still taken.
    defaultValue: 'https://edv-route-backend-production.up.railway.app/api/v1',
  );
}
