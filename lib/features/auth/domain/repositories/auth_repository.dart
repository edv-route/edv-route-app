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

  /// Clears the stored session.
  Future<void> logout();
}
