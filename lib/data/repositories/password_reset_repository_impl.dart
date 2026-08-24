import '../../core/network/api_client.dart';
import '../../domain/repositories/password_reset_repository.dart';

/// Talks to `/driver-auth/password-reset/*`. No token is threaded anywhere:
/// these are the only driver endpoints that are public, because a driver who
/// forgot his password cannot hold a session.
class PasswordResetRepositoryImpl implements PasswordResetRepository {
  PasswordResetRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<void> requestCode({required String nationalId, required String email}) =>
      _client.post('/driver-auth/password-reset/request', {
        'nationalId': nationalId,
        'email': email,
      });

  @override
  Future<String> verifyCode({
    required String nationalId,
    required String email,
    required String code,
  }) async {
    final res = await _client.post('/driver-auth/password-reset/verify', {
      'nationalId': nationalId,
      'email': email,
      'code': code,
    });
    return res['resetToken'] as String;
  }

  @override
  Future<void> confirm({required String resetToken, required String password}) =>
      _client.post('/driver-auth/password-reset/confirm', {
        'resetToken': resetToken,
        'password': password,
      });
}
