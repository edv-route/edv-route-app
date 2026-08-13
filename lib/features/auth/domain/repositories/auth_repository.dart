import '../entities/driver.dart';

/// Contract for driver authentication. The presentation layer depends on this
/// interface, never on the concrete data implementation.
abstract interface class AuthRepository {
  /// Authenticates a driver by national id (cédula) + password, persists the
  /// session token, and returns the driver profile. Throws [ApiException] on
  /// invalid credentials or transport errors.
  Future<Driver> loginDriver({
    required String nationalId,
    required String password,
  });

  /// The stored session token, or null if not logged in.
  Future<String?> currentToken();

  /// The current session's driver profile (GET /me) when a valid token is stored,
  /// or null when there is no session or it expired (the token is then cleared).
  /// Rethrows [ApiException] on transport errors so the caller can distinguish
  /// "no session" from "couldn't reach the server".
  Future<Driver?> currentDriver();

  /// Clears the stored session.
  Future<void> logout();
}
