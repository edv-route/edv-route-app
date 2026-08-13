/// Named routes for the app. Kept tiny and centralized so navigation targets are
/// referenced by constant, never by magic string. When the route graph grows,
/// this is the natural place to migrate to `go_router`.
abstract final class AppRoutes {
  const AppRoutes._();

  static const String selection = '/';
  static const String driverLogin = '/driver/login';
  /// Informational pre-screen (membership + benefits) that starts the join flow.
  static const String registerIntro = '/driver/register/info';
  static const String driverRegister = '/driver/register';
}
