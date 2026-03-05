import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dio_client.dart';
import 'token_storage.dart';

/// =======================
/// Secure Storage
/// =======================
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// =======================
/// Token Storage
/// =======================
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final storage = ref.read(secureStorageProvider);
  return TokenStorage(storage);
});

/// =======================
/// Dio Client
/// =======================
final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  return DioClient(tokenStorage: tokenStorage);
});
