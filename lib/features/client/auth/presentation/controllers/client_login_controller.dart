import 'package:flutter/foundation.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../../domain/repositories/client_auth_repository.dart';

/// Owns the state of the passenger login form: submits credentials and exposes
/// loading / error to the screen. Framework-agnostic ([ChangeNotifier]).
class ClientLoginController extends ChangeNotifier {
  ClientLoginController(this._repository);

  final ClientAuthRepository _repository;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  /// Attempts login. Returns the [Client] on success, or null on failure
  /// (with [error] populated for the UI).
  Future<Client?> login(String identifier, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final client = await _repository.login(
        identifier: normalizeIdentifier(identifier),
        password: password,
      );
      _loading = false;
      notifyListeners();
      return client;
    } on ApiException catch (e) {
      _fail(e.message);
      return null;
    } catch (_) {
      _fail('Ocurrió un error inesperado. Intenta de nuevo.');
      return null;
    }
  }

  void _fail(String message) {
    _error = message;
    _loading = false;
    notifyListeners();
  }

  /// Turns whatever the passenger typed into what the backend can match.
  ///
  /// The API compares the phone EXACTLY against the stored E.164 value
  /// (`+584121234567`), but nobody types it like that: they write
  /// "0412 123 4567" or "0412-1234567". Anything with an "@" is an email and
  /// passes through untouched; a phone-looking string is normalized to E.164.
  /// What fits neither shape also passes through, so the backend answers with
  /// its own "Datos incorrectos" instead of the app inventing a message.
  @visibleForTesting
  static String normalizeIdentifier(String raw) {
    final t = raw.trim();
    if (t.contains('@')) return t;
    final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
    // "04121234567" → national format with the leading 0.
    if (digits.length == 11 && digits.startsWith('0')) return '+58${digits.substring(1)}';
    // "+584121234567" or "584121234567" → already carries the country code.
    if (digits.length == 12 && digits.startsWith('58')) return '+$digits';
    // "4121234567" → typed without the leading 0.
    if (digits.length == 10) return '+58$digits';
    return t;
  }
}
