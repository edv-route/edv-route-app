import '../../core/network/api_client.dart';

/// Raw `/client-auth` API calls for the passenger side of the app.
class ClientRemoteDataSource {
  ClientRemoteDataSource(this._client);

  final ApiClient _client;

  /// POST /client-auth/login → `{ token, client }`. The identifier is his
  /// email or his phone in E.164, whichever he typed.
  Future<Map<String, dynamic>> login(String identifier, String password) =>
      _client.post('/client-auth/login', {
        'identifier': identifier,
        'password': password,
      });

  /// POST /client-auth/register → `{ token, client }`.
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) =>
      _client.post('/client-auth/register', body);

  /// POST /client-auth/register/check-cedula → `{ status }` (paso 0).
  Future<Map<String, dynamic>> checkCedula(String nationalId) =>
      _client.post('/client-auth/register/check-cedula', {'nationalId': nationalId});

  /// POST /client-auth/register/attach → `{ token, client }` (formulario corto).
  Future<Map<String, dynamic>> attach(Map<String, dynamic> body) =>
      _client.post('/client-auth/register/attach', body);

  /// GET /client-auth/me → the client's profile (bearer auth).
  Future<Map<String, dynamic>> me(String token) =>
      _client.get('/client-auth/me', token: token);

  /// PATCH /client-auth/me → the updated profile.
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body, {required String token}) =>
      _client.patch('/client-auth/me', body, token: token);

  /// POST /client-auth/me/photo (multipart) → `{ photoUrl }`.
  Future<Map<String, dynamic>> uploadPhoto(MultipartPart file, {required String token}) =>
      _client.postMultipart('/client-auth/me/photo', files: [file], token: token);
}
