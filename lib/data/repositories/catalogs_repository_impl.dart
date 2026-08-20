import '../../domain/entities/enrollment_cost.dart';
import '../../domain/entities/payment_method_option.dart';
import '../../domain/entities/requirement.dart';
import '../../domain/entities/vehicle_type_option.dart';
import '../../domain/repositories/catalogs_repository.dart';
import '../datasources/driver_remote_data_source.dart';

class CatalogsRepositoryImpl implements CatalogsRepository {
  const CatalogsRepositoryImpl(this._remote);

  final DriverRemoteDataSource _remote;

  @override
  Future<List<PaymentMethodOption>> loadPaymentMethods() async {
    final list = await _remote.paymentMethods();
    return list.map((e) => PaymentMethodOption.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<List<VehicleTypeOption>> loadVehicleTypes() async {
    final list = await _remote.vehicleTypes();
    return list.map((e) => VehicleTypeOption.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<List<Requirement>> loadVehicleRequirements() async {
    final list = await _remote.requirements();
    return list
        .map((e) => Requirement.fromJson((e as Map).cast<String, dynamic>()))
        .where((r) => r.isVehicle)
        .toList();
  }

  @override
  Future<MembershipInfo?> loadMembership() async {
    final data = await _remote.membership();
    if (data.isEmpty) return null; // backend returns null → empty map here
    return MembershipInfo.fromJson(data);
  }
}
