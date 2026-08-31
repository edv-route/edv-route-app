import '../../core/network/api_client.dart';
import '../../domain/repositories/password_reset_repository.dart';

/// The CLIENT channel: talks to `/client-auth/password-reset/*`. The passenger
/// proves himself with his email alone — he has no cédula on file, and the
/// email is both his identifier and where the code lands.
class ClientPasswordResetRepositoryImpl implements PasswordResetRepository {
  ClientPasswordResetRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<void> requestCode(ResetIdentity identity) =>
      _client.post('/client-auth/password-reset/request', {'email': identity.email});

  @override
  Future<String> verifyCode(ResetIdentity identity, String code) async {
    final res = await _client.post('/client-auth/password-reset/verify', {
      'email': identity.email,
      'code': code,
    });
    return res['resetToken'] as String;
  }

  @override
  Future<void> confirm({required String resetToken, required String password}) =>
      _client.post('/client-auth/password-reset/confirm', {
        'resetToken': resetToken,
        'password': password,
      });
}
