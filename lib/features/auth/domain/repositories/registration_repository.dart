import '../../data/models/register_request.dart';
import '../entities/alta_debt.dart';
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

  /// Registers a vehicle on the applicant's solicitud (POST /me/vehicles) and
  /// returns its id, so its photos can be uploaded with [uploadVehicleImage] and
  /// its documents added from the checklist.
  Future<String> addVehicle({
    int? vehicleTypeId,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? plate,
  });

  Future<void> uploadDocument(String documentId, PickedImage image);
  Future<void> uploadVehicleImage(String vehicleId, PickedImage image);

  /// A short-lived signed URL to preview the file of one of the driver's OWN
  /// documents (GET /documents/:id/file). The URL expires quickly (~60s), so it is
  /// fetched on demand when opening the document.
  Future<String> documentFileUrl(String documentId);

  /// The driver's alta/arrears debt (GET /me/debt), for the deferred payment.
  Future<AltaDebt> loadDebt();

  /// Submits the DEFERRED alta payment (purpose=`debt`, after approval): settles
  /// the whole owed debt and requires the terms & conditions acceptance. Left
  /// pending for an admin to approve. [weeks] is the TOTAL weeks paid at the alta
  /// (1 = base only; N = base + N-1 advance weeks, Forma A).
  Future<void> submitPayment(PaymentCapture capture, {required bool acceptedTerms, int weeks});
}
