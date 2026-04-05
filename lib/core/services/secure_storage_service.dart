import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _apiKeyKey = 'ai_api_key';

  Future<void> saveApiKey(String key) =>
      _storage.write(key: _apiKeyKey, value: key);

  Future<String?> getApiKey() => _storage.read(key: _apiKeyKey);

  Future<void> deleteApiKey() => _storage.delete(key: _apiKeyKey);

  Future<bool> hasApiKey() async {
    final key = await _storage.read(key: _apiKeyKey);
    return key != null && key.isNotEmpty;
  }

  Future<void> clearAll() => _storage.deleteAll();
}
