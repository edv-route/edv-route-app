import 'dart:io';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/token_storage.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/picked_image.dart';
import '../../domain/entities/vehicle_draft.dart';
import '../../domain/entities/vehicle_full.dart';
import '../../domain/repositories/enrollment_repository.dart';
import '../datasources/driver_remote_data_source.dart';
import '../models/register_request.dart';
import 'session_bound_repository.dart';

class EnrollmentRepositoryImpl extends SessionBoundRepository implements EnrollmentRepository {
  const EnrollmentRepositoryImpl(this._remote, TokenStorage tokenStorage) : super(tokenStorage);

  final DriverRemoteDataSource _remote;

  @override
  Future<RegisterResult> register(RegisterRequest request) async {
    final data = await _remote.register(request.toJson());
    final result = RegisterResult.fromJson(data);
    if (result.token.isEmpty) {
      throw const ApiException('Respuesta de registro incompleta.');
    }
    // Persist the token so the following uploads/payment are authenticated.
    await tokenStorage.saveToken(result.token);
    return result;
  }

  @override
  Future<Checklist> loadChecklist() async {
    final data = await _remote.checklist(token: await requireToken());
    return Checklist.fromJson(data);
  }

  @override
  Future<List<VehicleFull>> loadVehicles() async {
    final list = await _remote.vehicles(token: await requireToken());
    return list.map((e) => VehicleFull.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<String> addDocument({required int requirementId, String? vehicleId}) async {
    final data = await _remote.addDocument({
      'requirementId': requirementId,
      if (vehicleId != null) 'vehicleId': vehicleId,
    }, token: await requireToken());
    final id = data['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const ApiException('No se pudo registrar el documento.');
    }
    return id;
  }

  @override
  Future<String> submitVehicleDraft(VehicleDraft draft) => _sendDraft(draft, null);

  @override
  Future<String> resubmitVehicleDraft(String vehicleId, VehicleDraft draft) =>
      _sendDraft(draft, vehicleId);

  /// Reads the draft's files off the phone and posts the whole vehicle at once.
  /// Both paths send exactly the same payload — the endpoint is the only thing
  /// that changes — so a correction can never be validated differently.
  Future<String> _sendDraft(VehicleDraft draft, String? resubmitVehicleId) async {
    final files = <MultipartPart>[
      MultipartPart(
        field: 'photo',
        bytes: await File(draft.photoPath!).readAsBytes(),
        filename: 'foto.jpg',
      ),
      for (final doc in draft.documents)
        if (doc.localPath != null)
          MultipartPart(
            field: 'document_${doc.requirementId}',
            bytes: await File(doc.localPath!).readAsBytes(),
            filename: doc.fileName ?? 'documento_${doc.requirementId}',
          ),
    ];
    final data = await _remote.submitVehicle(
      {
        if (draft.vehicleTypeId != null) 'vehicleTypeId': '${draft.vehicleTypeId}',
        if (_notEmpty(draft.brand)) 'brand': draft.brand!,
        if (_notEmpty(draft.model)) 'model': draft.model!,
        if (draft.year != null) 'year': '${draft.year}',
        if (_notEmpty(draft.color)) 'color': draft.color!,
        if (_notEmpty(draft.plate)) 'plate': draft.plate!,
      },
      files,
      token: await requireToken(),
      resubmitVehicleId: resubmitVehicleId,
    );
    final id = data['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const ApiException('No se pudo enviar el vehículo.');
    }
    return id;
  }

  @override
  Future<void> setPrimaryVehicle(String vehicleId) async {
    await _remote.setPrimaryVehicle(vehicleId, token: await requireToken());
  }

  @override
  Future<void> uploadDocument(String documentId, PickedImage image) async {
    await _remote.uploadDocumentFile(documentId, part(image), token: await requireToken());
  }

  @override
  Future<String> documentFileUrl(String documentId) async {
    final data = await _remote.documentFileUrl(documentId, token: await requireToken());
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw const ApiException('No se pudo obtener el documento.');
    }
    return url;
  }

  @override
  Future<void> submitPayment(
    PaymentCapture capture, {
    required bool acceptedTerms,
    int weeks = 1,
  }) async {
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
    await _remote.submitPayment(fields, part(capture.receipt), token: await requireToken());
  }

  bool _notEmpty(String? value) => value != null && value.isNotEmpty;
}
