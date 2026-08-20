import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../domain/entities/picked_image.dart';
import '../../../../domain/entities/vehicle_draft.dart';
import '../../../../domain/entities/vehicle_type_option.dart';
import '../../../../domain/repositories/catalogs_repository.dart';
import '../../../../domain/repositories/enrollment_repository.dart';
import '../../../../data/repositories/vehicle_draft_store.dart';

/// Drives the vehicle draft: loads it from the phone, keeps every edit saved as
/// it happens, and sends the whole thing when the driver confirms (2026-08-20).
///
/// Saving on every change is deliberate. This gets filled standing next to the
/// vehicle, on a phone that rings, runs out of battery and loses signal; asking
/// him to remember to save would lose work, and there is nothing to gain by
/// waiting — the draft never leaves the device until he says so.
class VehicleDraftController extends ChangeNotifier {
  VehicleDraftController(this._store, this._enrollment, this._catalogs);

  final VehicleDraftStore _store;
  final EnrollmentRepository _enrollment;
  final CatalogsRepository _catalogs;

  VehicleDraft _draft = const VehicleDraft();
  List<VehicleTypeOption> _vehicleTypes = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  VehicleDraft get draft => _draft;
  List<VehicleTypeOption> get vehicleTypes => _vehicleTypes;
  bool get loading => _loading;
  bool get sending => _sending;
  String? get error => _error;

  /// True while the draft is a correction of a rejected vehicle.
  bool get isCorrection => _draft.correctingVehicleId != null;

  /// Loads the stored draft (if any) and the catalogs, then reconciles the draft
  /// with the requirements in force NOW: the admin may have added one since.
  Future<void> load({String? correctingVehicleId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final stored = await _store.load();
      final types = await _catalogs.loadVehicleTypes();
      final requirements = await _catalogs.loadVehicleRequirements();
      _vehicleTypes = types;
      var draft = stored ?? const VehicleDraft();
      // Starting a correction of a different vehicle throws away a draft that
      // belonged to another one: two drafts at a time was ruled out.
      if (correctingVehicleId != null && draft.correctingVehicleId != correctingVehicleId) {
        await _store.clear();
        draft = VehicleDraft(correctingVehicleId: correctingVehicleId);
      }
      _draft = draft.syncRequirements([
        for (final r in requirements) (id: r.id, name: r.name),
      ]);
      await _store.save(_draft);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo preparar el formulario. Revisa tu conexión.';
    }
    _loading = false;
    notifyListeners();
  }

  /// Updates the vehicle's data. Every field arrives as it is typed, so this is
  /// called often and must stay cheap.
  Future<void> updateData({
    int? vehicleTypeId,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? plate,
  }) async {
    _draft = _draft.copyWith(
      vehicleTypeId: vehicleTypeId,
      brand: brand,
      model: model,
      year: year,
      color: color,
      plate: plate,
    );
    await _persist();
  }

  /// Replaces the photo, dropping the copy it supersedes so the app's folder
  /// doesn't grow with every retake.
  Future<void> setPhoto(PickedImage image) async {
    final previous = _draft.photoPath;
    final stored = await _store.importBytes(image.bytes, prefix: 'photo', fileName: image.filename);
    _draft = _draft.copyWith(photoPath: stored);
    await _persist();
    if (previous != stored) await _store.discardFile(previous);
  }

  Future<void> setDocument(int requirementId, PickedImage file) async {
    final previous = _draft.documents
        .firstWhere((d) => d.requirementId == requirementId)
        .localPath;
    final stored = await _store.importBytes(
      file.bytes,
      prefix: 'doc$requirementId',
      fileName: file.filename,
    );
    _draft = _draft.withDocumentFile(requirementId, stored, file.filename);
    await _persist();
    if (previous != stored) await _store.discardFile(previous);
  }

  /// Sends the whole vehicle. On success the draft is thrown away: from here on
  /// it lives on the server and the local copies are dead weight. Returns false
  /// (with [error] set) when the backend refuses it — a duplicated plate, say.
  Future<bool> send() async {
    if (_sending || !_draft.isReadyToSend) return false;
    _sending = true;
    _error = null;
    notifyListeners();
    var sent = false;
    try {
      final correcting = _draft.correctingVehicleId;
      if (correcting != null) {
        await _enrollment.resubmitVehicleDraft(correcting, _draft);
      } else {
        await _enrollment.submitVehicleDraft(_draft);
      }
      await _store.clear();
      _draft = const VehicleDraft();
      sent = true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo enviar el vehículo. Intenta de nuevo.';
    }
    _sending = false;
    notifyListeners();
    return sent;
  }

  /// Throws the draft away at the driver's request.
  Future<void> discard() async {
    await _store.clear();
    _draft = const VehicleDraft();
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> _persist() async {
    notifyListeners();
    try {
      await _store.save(_draft);
    } catch (_) {
      // Losing one autosave is not worth interrupting him: the value is already
      // on screen and the next edit writes the whole draft again.
    }
  }
}
