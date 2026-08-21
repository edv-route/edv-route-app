import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../di.dart';

/// Push notifications (Firebase Cloud Messaging).
///
/// Deliberately thin: it only obtains the device token, hands it to the backend
/// and takes it back on logout. It does NOT decide what a notice says or when it
/// arrives — that lives on the server, where the wording can be fixed without
/// publishing an APK, and where the inbox and the push are guaranteed to agree.
///
/// Everything here is best-effort. A driver whose phone can never receive push
/// (Huawei without Play Services since 2019, permission denied on Android 13+)
/// must keep using the app exactly as before: the inbox is his channel, and it
/// works without any of this. So no failure below is ever shown to him.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  bool _started = false;
  String? _token;

  /// Firebase has to be up before anything asks for a token. Called once from
  /// `main`, before the first frame.
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (error) {
      // A device without Play Services throws here. The app must still open.
      debugPrint('Firebase no disponible en este dispositivo: $error');
    }
  }

  /// Asks for the permission (Android 13+ requires it explicitly), gets the
  /// token and registers it. Safe to call on every session start: registering
  /// is an upsert on the server, so repeating is the normal case.
  ///
  /// Also listens for rotation. FCM replaces tokens on its own — after a
  /// reinstall, a restore, or just because — and a token nobody re-registers is
  /// a driver who silently stops receiving anything.
  Future<void> syncToken() async {
    if (_started) return;
    _started = true;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // Not an error and not worth insisting: he still has the inbox.
        debugPrint('Avisos: permiso denegado, el chofer usará solo la bandeja');
        return;
      }

      final token = await messaging.getToken();
      if (token != null) await _register(token);

      messaging.onTokenRefresh.listen(_register);
    } catch (error) {
      debugPrint('Avisos: no se pudo registrar el teléfono: $error');
    }
  }

  Future<void> _register(String token) async {
    _token = token;
    try {
      await Dependencies.instance.notificationsRepository.registerDevice(token);
    } catch (error) {
      // The next session start registers it again. Nothing to tell him.
      debugPrint('Avisos: fallo al registrar el token: $error');
    }
  }

  /// Logout. Two doors have to close, and both matter:
  ///
  /// 1. The backend revokes the row, so nothing more is sent to this phone for
  ///    the driver who is leaving.
  /// 2. The token itself is deleted, so the next driver who signs in on this
  ///    handset gets a BRAND NEW one instead of inheriting this one.
  ///
  /// Without this, the next person to use the phone receives the previous
  /// driver's amounts and rejection reasons. It is privacy, not tidiness.
  ///
  /// Must run BEFORE the session token is cleared: revoking needs it.
  Future<void> disable() async {
    final token = _token;
    _started = false;
    _token = null;
    if (token == null) return;
    try {
      await Dependencies.instance.notificationsRepository.revokeDevice(token);
    } catch (error) {
      debugPrint('Avisos: no se pudo revocar el token: $error');
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (error) {
      debugPrint('Avisos: no se pudo borrar el token local: $error');
    }
  }
}
