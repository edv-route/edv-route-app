import '../../data/models/register_request.dart';
import '../entities/checklist.dart';
import '../entities/enrollment_cost.dart';
import '../entities/payment_method_option.dart';
import '../entities/picked_image.dart';
import '../entities/requirement.dart';
import '../entities/vehicle_type_option.dart';

/// Payment captured for the alta: the method + payer metadata + one receipt photo.
/// Mirrors the fields the backend `payment-submissions` endpoint accepts (cash is
/// admin-only and never offered in the app).
class PaymentCapture {
  final int paymentMethodId;
  final String? reference;
  final String? payerBank;
  final String paidOn; // ISO date (yyyy-MM-dd)
  final String? payerPhone;
  final String? payerId;
  final String? payerAccount;
  final PickedImage receipt;

  const PaymentCapture({
    required this.paymentMethodId,
    this.reference,
    this.payerBank,
    required this.paidOn,
    this.payerPhone,
    this.payerId,
    this.payerAccount,
    required this.receipt,
  });
}

/// Contract for the driver self-registration flow: the catalogs the wizard needs,
/// the alta, the authenticated file uploads and the payment submission. The
/// concrete implementation persists the token returned by [register] and reuses
/// it for the uploads.
abstract interface class RegistrationRepository {
  Future<List<Requirement>> loadRequirements();
  Future<List<PaymentMethodOption>> loadPaymentMethods();
  Future<List<VehicleTypeOption>> loadVehicleTypes();

  /// Current active membership for the alta summary, or null when none exists.
  Future<MembershipInfo?> loadMembership();

  /// Active tariffs for the alta summary (the app charges the weekly one).
  Future<List<TariffPlan>> loadPlans();

  /// Creates the alta (persists the returned token) and returns the created ids.
  Future<RegisterResult> register(RegisterRequest request);

  /// The applicant's "completa tu solicitud" checklist (documents + vehicles with
  /// their review state). Requires an active session (token from register/login).
  Future<Checklist> loadChecklist();

  /// Creates a document slot on the applicant's solicitud (POST /me/documents) and
  /// returns its id, so its file can then be attached with [uploadDocument].
  /// [vehicleId] is required for vehicle requirements, null for driver ones.
  Future<String> addDocument({required int requirementId, String? vehicleId});

  Future<void> uploadDocument(String documentId, PickedImage image);
  Future<void> uploadVehicleImage(String vehicleId, PickedImage image);

  /// Submits the alta payment as an `enroll` receipt covering membership +
  /// [periods] tariff weeks (left pending for an admin to approve).
  Future<void> submitPayment(PaymentCapture capture, {required int periods});
}
