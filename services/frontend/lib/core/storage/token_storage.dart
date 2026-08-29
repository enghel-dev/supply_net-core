import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste el JWT de sesión. `flutter_secure_storage` funciona en
/// Windows (DPAPI), Android (Keystore) y web (respaldo en memoria/local
/// storage), por lo que un mismo API sirve para los tres targets.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'supplynet_access_token';

  Future<void> save(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
