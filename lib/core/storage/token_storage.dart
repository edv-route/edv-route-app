import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists a session token in the platform secure store (Keychain on iOS,
/// EncryptedSharedPreferences/Keystore on Android).
///
/// One instance per session KIND: the driver and the client sessions live under
/// different keys, so an affiliate who is also a passenger never has one mode
/// clobbering the other's token.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage, String key = driverKey})
      : _storage = storage ?? const FlutterSecureStorage(),
        _tokenKey = key;

  static const String driverKey = 'driver_session_token';
  static const String clientKey = 'client_session_token';

  final String _tokenKey;
  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
