import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/models/register_request.dart';
import '../../../../domain/entities/driver.dart';
import '../../../../domain/repositories/registration_repository.dart';

/// Owns the driver registration STEP 1 (solicitudes-app): personal data + privacy
/// consent. Submitting creates an `applicant` (token persisted by the repository)
/// and the app then continues to the "completa tu solicitud" checklist, where the
/// documents, vehicles and (post-approval) payment are added via /me/*. The old
/// monolithic wizard (docs/vehicles/payment in the register payload) is gone: the
/// backend register body is step-1 only.
class DriverRegisterController extends ChangeNotifier {
  DriverRegisterController(this._repository);

  final RegistrationRepository _repository;

  bool _submitting = false;
  String? _error;

  bool get submitting => _submitting;
  String? get error => _error;

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Registers the applicant (step 1). Returns the created [Driver] on success —
  /// the token is persisted by the repository so the checklist calls are
  /// authenticated — or null with [error] populated for the UI.
  Future<Driver?> register(RegisterRequest request) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.register(request);
      _submitting = false;
      notifyListeners();
      return result.driver;
    } on ApiException catch (e) {
      _fail(e.message);
      return null;
    } catch (_) {
      _fail('No se pudo crear la solicitud. Intenta de nuevo.');
      return null;
    }
  }

  void _fail(String message) {
    _error = message;
    _submitting = false;
    notifyListeners();
  }
}
