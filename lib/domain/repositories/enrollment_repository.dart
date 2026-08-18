import '../../data/models/register_request.dart';
import '../entities/checklist.dart';
import '../entities/picked_image.dart';
import '../entities/vehicle_full.dart';

/// Payment captured for the alta: the method, the payer's details and one
/// receipt photo. Mirrors what the backend's payment endpoint accepts (cash is
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

/// The solicitud, end to end: creating the account, completing the checklist
/// (documents and vehicles with their files) and paying the alta once an admin
/// approves it. Everything past [register] needs the session it returns.
abstract interface class EnrollmentRepository {
  /// Creates the account (persists the returned token) and returns the ids created.
  Future<RegisterResult> register(RegisterRequest request);

  /// The applicant's checklist: documents and vehicles with their review state.
  Future<Checklist> loadChecklist();

  /// The driver's vehicles with full detail and signed photo URLs.
  Future<List<VehicleFull>> loadVehicles();

  /// Creates a document slot on the driver's OWN solicitud and returns its id, so
  /// its file can then be attached with [uploadDocument]. [vehicleId] is required
  /// for vehicle requirements, null for the driver's own.
  Future<String> addDocument({required int requirementId, String? vehicleId});

  /// Registers a vehicle on the driver's OWN solicitud and returns its id.
  Future<String> addVehicle({
    int? vehicleTypeId,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? plate,
  });

  /// Picks the vehicle he operates with. Choosing one releases the previous
  /// automatically; the backend refuses one that is not approved yet.
  Future<void> setPrimaryVehicle(String vehicleId);

  Future<void> uploadDocument(String documentId, PickedImage image);

  Future<void> uploadVehicleImage(String vehicleId, PickedImage image);

  /// A short-lived signed URL to preview one of the driver's OWN documents. It
  /// expires quickly (~60 s), so it is fetched on demand when opening the file.
  Future<String> documentFileUrl(String documentId);

  /// Submits the DEFERRED alta payment (after approval): settles the whole debt
  /// and requires accepting the terms. Left pending for an admin to review.
  /// [weeks] is the TOTAL paid at the alta (1 = base only; N = base + N-1 in
  /// advance).
  Future<void> submitPayment(PaymentCapture capture, {required bool acceptedTerms, int weeks});
}
