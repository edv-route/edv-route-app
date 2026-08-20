import '../data/datasources/auth_remote_data_source.dart';
import '../data/datasources/driver_remote_data_source.dart';
import '../data/repositories/account_repository_impl.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/catalogs_repository_impl.dart';
import '../data/repositories/enrollment_repository_impl.dart';
import '../domain/repositories/account_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/catalogs_repository.dart';
import '../data/repositories/notifications_repository_impl.dart';
import '../domain/repositories/enrollment_repository.dart';
import '../domain/repositories/notifications_repository.dart';
import './network/api_client.dart';
import './storage/token_storage.dart';

/// Tiny composition root wiring the concrete implementations together. A full
/// service locator (get_it) or DI framework can replace this later without
/// touching call sites, which depend on the interfaces.
///
/// The repositories are split by DOMAIN, not by screen: public catalogs, the
/// solicitud, and the driver's own account. Each caller asks for the one it
/// actually needs instead of receiving eighteen methods to use two.
class Dependencies {
  Dependencies._();

  static final Dependencies instance = Dependencies._();

  late final ApiClient _apiClient = ApiClient();
  late final DriverRemoteDataSource _driverApi = DriverRemoteDataSource(_apiClient);

  late final TokenStorage tokenStorage = TokenStorage();

  late final AuthRepository authRepository =
      AuthRepositoryImpl(AuthRemoteDataSource(_apiClient), tokenStorage);

  /// Public reference data: payment methods, vehicle types, membership.
  late final CatalogsRepository catalogsRepository = CatalogsRepositoryImpl(_driverApi);

  /// The solicitud: registration, checklist, documents, vehicles, alta payment.
  late final EnrollmentRepository enrollmentRepository =
      EnrollmentRepositoryImpl(_driverApi, tokenStorage);

  /// The driver's own account: debt, standing, personal data and photo.
  late final AccountRepository accountRepository =
      AccountRepositoryImpl(_driverApi, tokenStorage);

  /// His inbox: the notices the office and the debt engine send him.
  late final NotificationsRepository notificationsRepository =
      NotificationsRepositoryImpl(_driverApi, tokenStorage);
}
