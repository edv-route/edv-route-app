import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../domain/repositories/password_reset_repository.dart';

/// The DRIVER channel: talks to `/driver-auth/password-reset/*`. No token is
/// threaded anywhere: these are the only driver endpoints that are public,
/// because a driver who forgot his password cannot hold a session.
class PasswordResetRepositoryImpl implements PasswordResetRepository {
  PasswordResetRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<void> requestCode(ResetIdentity identity) =>
      _client.post('/driver-auth/password-reset/request', {
        'nationalId': _requireNationalId(identity),
        'email': identity.email,
      });

  @override
  Future<String> verifyCode(ResetIdentity identity, String code) async {
    final res = await _client.post('/driver-auth/password-reset/verify', {
      'nationalId': _requireNationalId(identity),
      'email': identity.email,
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

  /// The driver channel proves identity with the PAIR; an identity without the
  /// cédula is a programming error, caught here before it becomes a 400.
  String _requireNationalId(ResetIdentity identity) {
    final id = identity.nationalId;
    if (id == null || id.isEmpty) {
      throw const ApiException('Falta la cédula para recuperar la clave.');
    }
    return id;
  }
}
