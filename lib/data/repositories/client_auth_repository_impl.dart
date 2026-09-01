import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/picked_image.dart';
import '../../domain/repositories/client_auth_repository.dart';
import '../datasources/client_remote_data_source.dart';
import '../models/client_dto.dart';
import '../models/client_register_request.dart';
import 'session_bound_repository.dart';

/// Backed by the `/client-auth` endpoints, storing the session under the CLIENT
/// token key — separate from the driver's, so a person who is both never has
/// one mode wiping out the other's session.
class ClientAuthRepositoryImpl extends SessionBoundRepository implements ClientAuthRepository {
  const ClientAuthRepositoryImpl(this._remote, TokenStorage tokenStorage) : super(tokenStorage);

  final ClientRemoteDataSource _remote;

  @override
  Future<Client> login({required String identifier, required String password}) async {
    return _saveSession(await _remote.login(identifier, password));
  }

  @override
  Future<String> checkCedula(String nationalId) async {
    final data = await _remote.checkCedula(nationalId);
    return data['status'] as String? ?? 'new';
  }

  @override
  Future<Client> register(ClientRegisterRequest request) async {
    return _saveSession(await _remote.register(request.toJson()));
  }

  @override
  Future<Client> attach({
    required String nationalId,
    required String currentPassword,
    required String email,
    required String phone,
    required String password,
  }) async {
    return _saveSession(await _remote.attach({
      'nationalId': nationalId,
      'currentPassword': currentPassword,
      'email': email,
      'phone': phone,
      'password': password,
      'acceptedPrivacy': true,
    }));
  }

  @override
  Future<Client?> currentClient() async {
    final token = await tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      return clientFromJson(await _remote.me(token));
    } on ApiException catch (e) {
      // Expired/invalid session → clear it so the app falls back to selection.
      if (e.statusCode == 401 || e.statusCode == 403) {
        await tokenStorage.clear();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Client> updateProfile({
    String? firstName,
    String? middleName,
    String? lastName,
    String? secondLastName,
    String? phone,
    String? email,
    String? address,
    String? password,
    String? currentPassword,
  }) async {
    // Only the touched fields travel: the backend keeps whatever is absent.
    // Dart null = "don't touch"; an EMPTY string on an optional field means
    // "clear it" and travels as JSON null, because the backend's patterns
    // reject '' but its types accept null.
    final body = <String, dynamic>{
      if (firstName != null) 'firstName': firstName,
      if (middleName != null) 'middleName': middleName.isEmpty ? null : middleName,
      if (lastName != null) 'lastName': lastName,
      if (secondLastName != null) 'secondLastName': secondLastName.isEmpty ? null : secondLastName,
      if (phone != null) 'phone': phone.isEmpty ? null : phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address.isEmpty ? null : address,
      if (password != null) 'password': password,
      if (password != null && currentPassword != null) 'currentPassword': currentPassword,
    };
    return clientFromJson(await _remote.updateMe(body, token: await requireToken()));
  }

  @override
  Future<String?> uploadProfilePhoto(PickedImage image) async {
    final json = await _remote.uploadPhoto(part(image), token: await requireToken());
    return json['photoUrl'] as String?;
  }

  @override
  Future<void> logout() => tokenStorage.clear();

  /// Persists the token from a `{ token, client }` payload and returns the
  /// profile, failing loudly when either half is missing.
  Future<Client> _saveSession(Map<String, dynamic> data) async {
    final token = data['token'] as String?;
    final clientJson = data['client'] as Map<String, dynamic>?;
    if (token == null || clientJson == null) {
      throw const ApiException('Respuesta de autenticación incompleta.');
    }
    await tokenStorage.saveToken(token);
    return clientFromJson(clientJson);
  }
}
