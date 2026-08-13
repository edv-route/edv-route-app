import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/enrollment_cost.dart';
import '../../domain/entities/payment_method_option.dart';
import '../../domain/entities/picked_image.dart';
import '../../domain/entities/requirement.dart';
import '../../domain/entities/vehicle_type_option.dart';
import '../../domain/repositories/registration_repository.dart';
import '../datasources/registration_remote_data_source.dart';
import '../models/register_request.dart';

class RegistrationRepositoryImpl implements RegistrationRepository {
  RegistrationRepositoryImpl(this._remote, this._tokenStorage);

  final RegistrationRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<List<Requirement>> loadRequirements() async {
    final list = await _remote.requirements();
    return list.map((e) => Requirement.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

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
  Future<MembershipInfo?> loadMembership() async {
    final data = await _remote.membership();
    if (data.isEmpty) return null; // backend returns null → empty map here
    return MembershipInfo.fromJson(data);
  }

  @override
  Future<List<TariffPlan>> loadPlans() async {
    final list = await _remote.subscriptionPlans();
    return list.map((e) => TariffPlan.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<RegisterResult> register(RegisterRequest request) async {
    final data = await _remote.register(request.toJson());
    final result = RegisterResult.fromJson(data);
    if (result.token.isEmpty) {
      throw const ApiException('Respuesta de registro incompleta.');
    }
    // Persist the token so the following uploads/payment are authenticated.
    await _tokenStorage.saveToken(result.token);
    return result;
  }

  @override
  Future<Checklist> loadChecklist() async {
    final token = await _requireToken();
    final data = await _remote.checklist(token: token);
    return Checklist.fromJson(data);
  }

  @override
  Future<void> uploadDocument(String documentId, PickedImage image) async {
    final token = await _requireToken();
    await _remote.uploadDocumentFile(documentId, _part(image), token: token);
  }

  @override
  Future<void> uploadVehicleImage(String vehicleId, PickedImage image) async {
    final token = await _requireToken();
    await _remote.uploadVehicleImage(vehicleId, _part(image), token: token);
  }

  @override
  Future<void> submitPayment(PaymentCapture capture, {required int periods}) async {
    final token = await _requireToken();
    final fields = <String, String>{
      // The alta is paid as an `enroll` receipt = membership + N tariff weeks.
      'purpose': 'enroll',
      'periods': '$periods',
      'paymentMethodId': '${capture.paymentMethodId}',
      'paidOn': capture.paidOn,
      if (_notEmpty(capture.reference)) 'reference': capture.reference!,
      if (_notEmpty(capture.payerBank)) 'payerBank': capture.payerBank!,
      if (_notEmpty(capture.payerPhone)) 'payerPhone': capture.payerPhone!,
      if (_notEmpty(capture.payerId)) 'payerId': capture.payerId!,
      if (_notEmpty(capture.payerAccount)) 'payerAccount': capture.payerAccount!,
    };
    await _remote.submitPayment(fields, _part(capture.receipt), token: token);
  }

  Future<String> _requireToken() async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException('Sesión no iniciada. Vuelve a empezar el registro.');
    }
    return token;
  }

  MultipartPart _part(PickedImage img) =>
      MultipartPart(field: 'file', bytes: img.bytes, filename: img.filename);

  bool _notEmpty(String? v) => v != null && v.isNotEmpty;
}
