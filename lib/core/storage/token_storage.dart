import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the driver session token in the platform secure store
/// (Keychain on iOS, EncryptedSharedPreferences/Keystore on Android).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'driver_session_token';
  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
