import 'package:flutter/foundation.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../../../data/models/client_register_request.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../../domain/repositories/client_auth_repository.dart';

/// Owns the passenger registration: submits the form and exposes submitting /
/// error to the screen. The token is persisted by the repository, so a
/// successful registration IS a signed-in session — no second login step.
class ClientRegisterController extends ChangeNotifier {
  ClientRegisterController(this._repository);

  final ClientAuthRepository _repository;

  bool _submitting = false;
  String? _error;

  bool get submitting => _submitting;
  String? get error => _error;

  /// Registers the client. Returns the created [Client] on success, or null
  /// with [error] populated for the UI.
  Future<Client?> register(ClientRegisterRequest request) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      final client = await _repository.register(request);
      _submitting = false;
      notifyListeners();
      return client;
    } on ApiException catch (e) {
      _fail(e.message);
      return null;
    } catch (_) {
      _fail('No se pudo crear tu cuenta. Intenta de nuevo.');
      return null;
    }
  }

  void _fail(String message) {
    _error = message;
    _submitting = false;
    notifyListeners();
  }
}
