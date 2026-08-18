import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/alta_debt.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/enrollment_cost.dart';
import '../../domain/entities/payment_method_option.dart';
import '../../domain/entities/picked_image.dart';
import '../../domain/entities/requirement.dart';
import '../../domain/entities/vehicle_full.dart';
import '../../domain/entities/vehicle_type_option.dart';
import '../../domain/repositories/registration_repository.dart';
import '../datasources/registration_remote_data_source.dart';
import '../models/driver_dto.dart';
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
  Future<List<VehicleFull>> loadVehicles() async {
    final token = await _requireToken();
    final list = await _remote.vehicles(token: token);
    return list.map((e) => VehicleFull.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<String> addDocument({required int requirementId, String? vehicleId}) async {
    final token = await _requireToken();
    final data = await _remote.addDocument({
      'requirementId': requirementId,
      if (vehicleId != null) 'vehicleId': vehicleId,
    }, token: token);
    final id = data['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const ApiException('No se pudo registrar el documento.');
    }
    return id;
  }

  @override
  Future<String> addVehicle({
    int? vehicleTypeId,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? plate,
  }) async {
    final token = await _requireToken();
    final data = await _remote.addVehicle({
      if (vehicleTypeId != null) 'vehicleTypeId': vehicleTypeId,
      if (brand != null && brand.isNotEmpty) 'brand': brand,
      if (model != null && model.isNotEmpty) 'model': model,
      if (year != null) 'year': year,
      if (color != null && color.isNotEmpty) 'color': color,
      if (plate != null && plate.isNotEmpty) 'plate': plate,
    }, token: token);
    final id = data['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const ApiException('No se pudo registrar el vehículo.');
    }
    return id;
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
  Future<String> documentFileUrl(String documentId) async {
    final token = await _requireToken();
    final data = await _remote.documentFileUrl(documentId, token: token);
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw const ApiException('No se pudo obtener el documento.');
    }
    return url;
  }

  @override
  Future<AltaDebt> loadDebt() async {
    final token = await _requireToken();
    final data = await _remote.debt(token: token);
    return AltaDebt.fromJson(data);
  }

  @override
  Future<void> submitPayment(PaymentCapture capture, {required bool acceptedTerms, int weeks = 1}) async {
    final token = await _requireToken();
    final fields = <String, String>{
      // Deferred alta payment: settle the whole owed debt after approval, with the
      // terms & conditions acceptance the backend gate requires.
      'purpose': 'debt',
      'acceptedTerms': acceptedTerms ? 'true' : 'false',
      'paymentMethodId': '${capture.paymentMethodId}',
      'paidOn': capture.paidOn,
      // Forma A: total weeks paid at the alta (base + advance). Omitted when 1.
      if (weeks > 1) 'periods': '$weeks',
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

  @override
  Future<AccountStatus> loadAccount() async {
    final token = await _requireToken();
    return AccountStatus.fromJson(await _remote.account(token: token));
  }

  @override
  Future<String?> loadAddress() async {
    final token = await _requireToken();
    final json = await _remote.editableData(token: token);
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
    final token = await _requireToken();
    // Only the touched fields travel: the backend keeps whatever is absent, so
    // sending nulls would wipe data the driver never opened.
    final body = <String, dynamic>{
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (password != null) 'password': password,
      if (password != null && currentPassword != null) 'currentPassword': currentPassword,
    };
    return driverFromJson(await _remote.updateMe(body, token: token));
  }

  @override
  Future<String?> uploadProfilePhoto(PickedImage image) async {
    final token = await _requireToken();
    final json = await _remote.uploadPhoto(_part(image), token: token);
    return json['photoUrl'] as String?;
  }

  MultipartPart _part(PickedImage img) =>
      MultipartPart(field: 'file', bytes: img.bytes, filename: img.filename);

  bool _notEmpty(String? v) => v != null && v.isNotEmpty;
}
