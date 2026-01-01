import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/providers.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';

// ===============================
// PROVIDERS
// ===============================
final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

// ===============================
// CONTROLLER
// ===============================
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repo) : super(const AsyncData(null));

  final AuthRepository _repo;

  // ===============================
  // LOGIN (username + password)
  // ===============================
  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.login(username, password),
    );
  }

  // ===============================
  // GOOGLE LOGIN ✅ (النهائي)
  // ===============================
  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId:
            '839005087126-rc1kc0ujab07u2njkcc2ara0pcvcj3qh.apps.googleusercontent.com',
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        throw Exception('تم إلغاء تسجيل الدخول باستخدام Google');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        throw Exception('فشل الحصول على Google ID Token');
      }

      await _repo.googleLogin(idToken);
    });
  }

  // ===============================
  // REGISTER
  // ===============================
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.register(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  // ===============================
  // LOGOUT
  // ===============================
  Future<void> logout() async {
    await _repo.logout();
  }
}
