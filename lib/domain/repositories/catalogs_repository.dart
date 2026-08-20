import '../entities/enrollment_cost.dart';
import '../entities/payment_method_option.dart';
import '../entities/requirement.dart';
import '../entities/vehicle_type_option.dart';

/// Public reference data the app needs before (and while) filling a solicitud:
/// the payment methods offered, the vehicle types and the current membership.
/// None of it belongs to a driver, so none of it needs a session.
abstract interface class CatalogsRepository {
  Future<List<PaymentMethodOption>> loadPaymentMethods();

  Future<List<VehicleTypeOption>> loadVehicleTypes();

  /// Active VEHICLE document requirements. A vehicle draft needs them before the
  /// vehicle exists anywhere, so they cannot be read off the checklist.
  Future<List<Requirement>> loadVehicleRequirements();

  /// Current membership (name, price and benefits), or null when none is active.
  Future<MembershipInfo?> loadMembership();
}
