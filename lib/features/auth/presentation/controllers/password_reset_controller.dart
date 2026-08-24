import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../domain/repositories/password_reset_repository.dart';

/// Owns the whole recovery flow — the three screens share ONE controller.
///
/// Splitting it per screen would mean threading the cédula, the email and the
/// reset token through three constructors, and every one of those hand-offs is
/// a chance for the code screen and the password screen to disagree about whose
/// account is being recovered. Here that answer exists once.
class PasswordResetController extends ChangeNotifier {
  PasswordResetController(this._repository);

  final PasswordResetRepository _repository;

  /// How long the driver has to type the code, mirrored from the server. If the
  /// two ever drift the server wins — this only drives the countdown.
  static const Duration codeLifetime = Duration(minutes: 10);

  /// The server refuses a new code before this elapses; the UI greys out
  /// "Reenviar" for the same span instead of letting him earn an error.
  static const Duration resendCooldown = Duration(seconds: 60);

  String _nationalId = '';
  String _email = '';
  String? _resetToken;

  bool _loading = false;
  String? _error;

  Timer? _ticker;
  Duration _remaining = Duration.zero;
  Duration _untilResend = Duration.zero;

  bool get loading => _loading;
  String? get error => _error;
  String get email => _email;

  /// Time left before the code dies. Drives the "Vence en 9:32" line.
  Duration get remaining => _remaining;

  /// Zero once "Reenviar código" becomes tappable.
  Duration get untilResend => _untilResend;

  bool get expired => _remaining <= Duration.zero;

  /// Step 1. Keeps the pair on success so the later steps never re-ask for it.
  Future<bool> requestCode({required String nationalId, required String email}) async {
    _begin();
    try {
      await _repository.requestCode(nationalId: nationalId, email: email);
      _nationalId = nationalId;
      _email = email;
      _startCountdown();
      _done();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  /// Asks for another code for the same account. Restarts both clocks.
  Future<bool> resendCode() async {
    if (_untilResend > Duration.zero) return false;
    return requestCode(nationalId: _nationalId, email: _email);
  }

  /// Step 2. On success the token is held here, never handed to the screen:
  /// there is nothing a screen can usefully do with it except pass it back.
  Future<bool> verifyCode(String code) async {
    _begin();
    try {
      _resetToken = await _repository.verifyCode(
        nationalId: _nationalId,
        email: _email,
        code: code,
      );
      _done();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  /// Step 3.
  Future<bool> confirm(String password) async {
    final token = _resetToken;
    if (token == null) {
      _error = 'Vuelve a pedir un código.';
      notifyListeners();
      return false;
    }
    _begin();
    try {
      await _repository.confirm(resetToken: token, password: password);
      _ticker?.cancel();
      _done();
      return true;
    } catch (e) {
      _fail(e);
      return false;
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _startCountdown() {
    _ticker?.cancel();
    _remaining = codeLifetime;
    _untilResend = resendCooldown;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      _remaining -= const Duration(seconds: 1);
      if (_untilResend > Duration.zero) _untilResend -= const Duration(seconds: 1);
      if (_remaining <= Duration.zero) t.cancel();
      notifyListeners();
    });
  }

  void _begin() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void _done() {
    _loading = false;
    notifyListeners();
  }

  void _fail(Object e) {
    // The server's message is the one shown: it is already written in Spanish
    // for this driver ("Te quedan 2 intentos"), and it knows things the app
    // cannot ("Espera 47 segundos"). Only an unrecognised failure gets a
    // generic line.
    _error = e is ApiException ? e.message : 'Ocurrió un error inesperado. Intenta de nuevo.';
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
