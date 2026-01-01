import '../../../core/network/token_storage.dart';
import '../domain/auth_tokens.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required TokenStorage tokenStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage;

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  Future<void> login(String username, String password) async {
    final AuthTokens tokens =
        await _api.login(username: username, password: password);

    await _tokenStorage.saveAccessToken(tokens.accessToken);
  }

  Future<void> googleLogin(String idToken) async {
    final AuthTokens tokens = await _api.googleLogin(idToken: idToken);

    await _tokenStorage.saveAccessToken(tokens.accessToken);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _api.register(
      username: username,
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
  }
}
