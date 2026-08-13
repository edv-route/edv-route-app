import '../../../../core/network/api_client.dart';

/// Raw auth API calls for the driver app.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final ApiClient _client;

  /// POST /driver-auth/login → `{ token, driver }`.
  Future<Map<String, dynamic>> login(String nationalId, String password) =>
      _client.post('/driver-auth/login', {
        'nationalId': nationalId,
        'password': password,
      });

  /// GET /driver-auth/me → the driver's public profile (bearer auth).
  Future<Map<String, dynamic>> me(String token) => _client.get('/driver-auth/me', token: token);
}
