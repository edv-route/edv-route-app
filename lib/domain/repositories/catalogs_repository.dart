import '../entities/enrollment_cost.dart';
import '../entities/payment_method_option.dart';
import '../entities/vehicle_type_option.dart';

/// Public reference data the app needs before (and while) filling a solicitud:
/// the payment methods offered, the vehicle types and the current membership.
/// None of it belongs to a driver, so none of it needs a session.
abstract interface class CatalogsRepository {
  Future<List<PaymentMethodOption>> loadPaymentMethods();

  Future<List<VehicleTypeOption>> loadVehicleTypes();

  /// Current membership (name, price and benefits), or null when none is active.
  Future<MembershipInfo?> loadMembership();
}
