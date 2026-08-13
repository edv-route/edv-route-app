import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/datasources/registration_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/data/repositories/registration_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/repositories/registration_repository.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';

/// Tiny composition root wiring the concrete implementations together. A full
/// service locator (get_it) or DI framework can replace this later without
/// touching call sites, which depend on the interfaces.
class Dependencies {
  Dependencies._();

  static final Dependencies instance = Dependencies._();

  late final ApiClient _apiClient = ApiClient();
  late final TokenStorage tokenStorage = TokenStorage();
  late final AuthRepository authRepository =
      AuthRepositoryImpl(AuthRemoteDataSource(_apiClient), tokenStorage);
  late final RegistrationRepository registrationRepository =
      RegistrationRepositoryImpl(RegistrationRemoteDataSource(_apiClient), tokenStorage);
}
