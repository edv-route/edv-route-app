import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/picked_image.dart';
import '../../domain/repositories/registration_repository.dart';

/// Owns the "completa tu solicitud" checklist state: loads the applicant's
/// document/vehicle review status and drives the upload actions (create the slot
/// via /me/documents when needed, then attach the file via /documents/:id/file).
/// Requires an active session (token persisted at register/login).
class ChecklistController extends ChangeNotifier {
  ChecklistController(this._repository);

  final RegistrationRepository _repository;

  bool _loading = true;
  String? _error;
  Checklist? _checklist;

  /// Which item is uploading right now (keyed by vehicleId-or-driver + requirement),
  /// so only that row shows a spinner. Null when idle.
  String? _uploadingKey;
  String? _actionError;

  bool get loading => _loading;
  String? get error => _error;
  Checklist? get checklist => _checklist;
  String? get actionError => _actionError;

  bool isUploading(int requirementId, {String? vehicleId}) =>
      _uploadingKey == _keyFor(requirementId, vehicleId);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _checklist = await _repository.loadChecklist();
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

  void clearActionError() {
    if (_actionError != null) {
      _actionError = null;
      notifyListeners();
    }
  }

  String _keyFor(int requirementId, String? vehicleId) => '${vehicleId ?? 'driver'}:$requirementId';
}
