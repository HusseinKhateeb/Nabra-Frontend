import '../../../core/network/token_storage.dart';
import '../domain/auth_tokens.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository({required AuthApi api, required TokenStorage tokenStorage})
      : _api = api,
        _tokenStorage = tokenStorage;

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  Future<void> login(String email, String password) async {
    final AuthTokens tokens = await _api.login(email: email, password: password);
    await _tokenStorage.saveAccessToken(tokens.accessToken);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String preferredLanguage = 'en',
  }) async {
    await _api.register(
      fullName: fullName,
      email: email,
      password: password,
      preferredLanguage: preferredLanguage,
    );
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
  }
}
