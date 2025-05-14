import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  final _storage = FlutterSecureStorage();

  Future<void> saveAccessCode(String code) async {
    await _storage.write(key: 'access_code', value: code);
  }

  Future<String?> getAccessCode() async {
    return await _storage.read(key: 'access_code');
  }

  Future<void> deleteAccessCode() async {
    await _storage.delete(key: 'access_code');
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
