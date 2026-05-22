import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/token_storage.dart';

import './../data/auth_api.dart';
import './../data/auth_repository.dart';

/// ===============================
/// Secure Storage
/// ===============================
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// ===============================
/// Token Storage
/// ===============================
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  return TokenStorage(secureStorage);
});

/// ===============================
/// Dio Client
/// ===============================
final dioClientProvider = Provider<DioClient>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  return DioClient(tokenStorage: tokenStorage);
});

/// ===============================
/// Auth API
/// ===============================
final authApiProvider = Provider<AuthApi>((ref) {
  final client = ref.read(dioClientProvider);
  return AuthApi(client);
});

/// ===============================
/// Auth Repository
/// ===============================
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.read(authApiProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

/// ===============================
/// Access Token Provider
/// ===============================
final authTokenProvider = FutureProvider<String?>((ref) async {
  final storage = ref.read(tokenStorageProvider);
  return storage.readAccessToken();
});
