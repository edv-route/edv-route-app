import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/repositories/registration_repository.dart';

/// Owns the "completa tu solicitud" checklist state: loads the applicant's
/// document/vehicle review status and exposes loading / error / data to the UI.
/// Requires an active session (token persisted at register/login).
class ChecklistController extends ChangeNotifier {
  ChecklistController(this._repository);

  final RegistrationRepository _repository;

  bool _loading = true;
  String? _error;
  Checklist? _checklist;

  bool get loading => _loading;
  String? get error => _error;
  Checklist? get checklist => _checklist;

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
}
