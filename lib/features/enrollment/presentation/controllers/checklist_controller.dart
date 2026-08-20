import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../domain/entities/checklist.dart';
import '../../../../domain/entities/picked_image.dart';
import '../../../../domain/entities/vehicle_type_option.dart';
import '../../../../domain/repositories/catalogs_repository.dart';
import '../../../../domain/repositories/enrollment_repository.dart';

/// Owns the "completa tu solicitud" checklist state: loads the applicant's
/// document/vehicle review status and drives the actions — upload a document
/// (create the slot via /me/documents when needed, then attach the file) and add
/// a vehicle (POST /me/vehicles + upload its photos). Requires an active session.
class ChecklistController extends ChangeNotifier {
  ChecklistController(this._repository, this._catalogs);

  final EnrollmentRepository _repository;
  final CatalogsRepository _catalogs;

  bool _loading = true;
  String? _error;
  Checklist? _checklist;
  List<VehicleTypeOption> _vehicleTypes = const [];

  /// Which document is uploading (keyed by vehicleId-or-driver + requirement), so
  /// only that row shows a spinner. Null when idle.
  String? _uploadingKey;
  String? _actionError;

  bool get loading => _loading;
  String? get error => _error;
  Checklist? get checklist => _checklist;
  List<VehicleTypeOption> get vehicleTypes => _vehicleTypes;
  String? get actionError => _actionError;

  bool isUploading(int requirementId, {String? vehicleId}) =>
      _uploadingKey == _keyFor(requirementId, vehicleId);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _checklist = await _repository.loadChecklist();
      // Vehicle types feed the "add vehicle" form; a failure must not break the
      // checklist (the type is optional), so it degrades to an empty selector.
      if (_vehicleTypes.isEmpty) {
        try {
          _vehicleTypes = await _catalogs.loadVehicleTypes();
        } catch (_) {
          _vehicleTypes = const [];
        }
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo cargar tu solicitud. Intenta de nuevo.';
    }
    _loading = false;
    notifyListeners();
  }

  /// Uploads (or replaces) a document's file. Creates the slot first when it does
  /// not exist yet ([doc.documentId] null). [vehicleId] is set for a vehicle's
  /// document, null for a driver one. Refreshes the checklist on success.
  Future<void> uploadDocument({
    required ChecklistDocument doc,
    String? vehicleId,
    required PickedImage image,
  }) async {
    if (_uploadingKey != null) return; // one upload at a time
    _uploadingKey = _keyFor(doc.requirementId, vehicleId);
    _actionError = null;
    notifyListeners();
    try {
      final docId = doc.documentId ??
          await _repository.addDocument(requirementId: doc.requirementId, vehicleId: vehicleId);
      await _repository.uploadDocument(docId, image);
      _checklist = await _repository.loadChecklist();
    } on ApiException catch (e) {
      _actionError = e.message;
    } catch (_) {
      _actionError = 'No se pudo subir el documento. Intenta de nuevo.';
    }
    _uploadingKey = null;
    notifyListeners();
  }

  /// A short-lived signed URL to preview a document's uploaded file (fetched on
  /// demand; the URL expires quickly).
  Future<String> documentFileUrl(String documentId) =>
      _repository.documentFileUrl(documentId);

  void clearActionError() {
    if (_actionError != null) {
      _actionError = null;
      notifyListeners();
    }
  }

  String _keyFor(int requirementId, String? vehicleId) => '${vehicleId ?? 'driver'}:$requirementId';
}
