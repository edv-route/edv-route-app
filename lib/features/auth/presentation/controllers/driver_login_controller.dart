import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../domain/entities/driver.dart';
import '../../../../domain/repositories/auth_repository.dart';

/// Owns the state of the driver login form: submits credentials and exposes
/// loading / error to the screen. Framework-agnostic ([ChangeNotifier]).
class DriverLoginController extends ChangeNotifier {
  DriverLoginController(this._repository);

  final AuthRepository _repository;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  /// Attempts login. Returns the [Driver] on success, or null on failure
  /// (with [error] populated for the UI).
  Future<Driver?> login(String nationalId, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final driver = await _repository.loginDriver(
        nationalId: nationalId,
        password: password,
      );
      _loading = false;
      notifyListeners();
      return driver;
    } on ApiException catch (e) {
      _fail(e.message);
      return null;
    } catch (_) {
      _fail('Ocurrió un error inesperado. Intenta de nuevo.');
      return null;
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _fail(String message) {
    _error = message;
    _loading = false;
    notifyListeners();
  }
}
