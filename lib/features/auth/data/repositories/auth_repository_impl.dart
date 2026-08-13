import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/driver.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/driver_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokenStorage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<Driver> loginDriver({
    required String nationalId,
    required String password,
  }) async {
    final data = await _remote.login(nationalId, password);
    final token = data['token'] as String?;
    final driverJson = data['driver'] as Map<String, dynamic>?;
    if (token == null || driverJson == null) {
      throw const ApiException('Respuesta de autenticación incompleta.');
    }
    await _tokenStorage.saveToken(token);
    return driverFromJson(driverJson);
  }

  @override
  Future<String?> currentToken() => _tokenStorage.readToken();

  @override
  Future<void> logout() => _tokenStorage.clear();
}
