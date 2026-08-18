import '../../core/storage/token_storage.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/alta_debt.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/picked_image.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/driver_remote_data_source.dart';
import '../models/driver_dto.dart';
import 'session_bound_repository.dart';

class AccountRepositoryImpl extends SessionBoundRepository implements AccountRepository {
  const AccountRepositoryImpl(this._remote, TokenStorage tokenStorage) : super(tokenStorage);

  final DriverRemoteDataSource _remote;

  @override
  Future<AltaDebt> loadDebt() async {
    return AltaDebt.fromJson(await _remote.debt(token: await requireToken()));
  }

  @override
  Future<AccountStatus> loadAccount() async {
    return AccountStatus.fromJson(await _remote.account(token: await requireToken()));
  }

  @override
  Future<String?> loadAddress() async {
    final json = await _remote.editableData(token: await requireToken());
    return json['address'] as String?;
  }

  @override
  Future<Driver> updateOwnProfile({
    String? phone,
    String? email,
    String? address,
    String? password,
    String? currentPassword,
  }) async {
    // Only the touched fields travel: the backend keeps whatever is absent, so
    // sending nulls would wipe data the driver never opened.
    final body = <String, dynamic>{
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (password != null) 'password': password,
      if (password != null && currentPassword != null) 'currentPassword': currentPassword,
    };
    return driverFromJson(await _remote.updateMe(body, token: await requireToken()));
  }

  @override
  Future<bool> setAvailability(bool available) async {
    final json = await _remote.setAvailability(available, token: await requireToken());
    return json['isAvailable'] as bool? ?? available;
  }

  @override
  Future<String?> uploadProfilePhoto(PickedImage image) async {
    final json = await _remote.uploadPhoto(part(image), token: await requireToken());
    return json['photoUrl'] as String?;
  }
}
