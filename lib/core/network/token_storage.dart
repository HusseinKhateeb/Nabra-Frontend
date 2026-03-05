import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../../shared/constants.dart';

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const String _legacyAccessTokenKey = 'access_token';

  Future<void> saveAccessToken(String token) async {
    final String normalized = token.trim().startsWith('Bearer ')
        ? token.trim().substring(7).trim()
        : token.trim();
    await _storage.write(key: StorageKeys.accessToken, value: normalized);
    // Keep legacy key in sync for old code paths during migration.
    await _storage.write(key: _legacyAccessTokenKey, value: normalized);

    if (kDebugMode) {
      final String tail = normalized.length > 8
          ? normalized.substring(normalized.length - 8)
          : normalized;
      debugPrint('[Auth][TokenSaved] tail=$tail');
    }
  }

  Future<String?> readAccessToken() async {
    final String? raw = await _storage.read(key: StorageKeys.accessToken) ??
        await _storage.read(key: _legacyAccessTokenKey);
    if (raw == null) return null;

    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Backward compatibility for previously stored "Bearer <jwt>" values.
    return trimmed.startsWith('Bearer ')
        ? trimmed.substring(7).trim()
        : trimmed;
  }

  // =====================
  // Helper for UI / Chat
  // =====================
  Future<String?> getToken() async {
    return readAccessToken();
  }

  Future<void> clear() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: _legacyAccessTokenKey);
    await _storage.delete(key: StorageKeys.refreshToken);
  }
}
