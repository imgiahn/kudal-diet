import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _nicknameKey = 'nickname';

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<String?> getUserId() => _storage.read(key: _userIdKey);
  Future<String?> getNickname() => _storage.read(key: _nicknameKey);

  Future<void> save({
    required String token,
    required String userId,
    required String nickname,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _nicknameKey, value: nickname),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _nicknameKey),
    ]);
  }
}
