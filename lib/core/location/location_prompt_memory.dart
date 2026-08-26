import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers whether the location explanation has already been shown once.
///
/// It exists for one reason: the screen is shown on FIRST launch so the driver
/// arrives prepared, and without a memory it would reappear on every single
/// launch for anyone who said "ahora no". Being nagged at every open is how an
/// app gets uninstalled.
///
/// Turning the switch on still shows it again regardless — there the driver is
/// asking for something that needs the permission, so the ask is earned.
class LocationPromptMemory {
  LocationPromptMemory([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'location_prompt_shown';
  final FlutterSecureStorage _storage;

  Future<bool> wasShown() async => await _storage.read(key: _key) == 'true';

  Future<void> markShown() => _storage.write(key: _key, value: 'true');

  /// Logout clears it: the next driver on this phone gets the explanation too.
  Future<void> clear() => _storage.delete(key: _key);
}
