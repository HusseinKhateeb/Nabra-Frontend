import 'package:dio/dio.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_tokens.dart';

class AuthApi {
  AuthApi(this._client);

  final DioClient _client;

  Future<AuthTokens> login({required String email, required String password}) async {
    final Response res = await _client.dio.post(
      ApiEndpoints.authLogin,
      data: {'email': email, 'password': password},
    );
    return AuthTokens.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String preferredLanguage = 'en',
  }) async {
    await _client.dio.post(
      ApiEndpoints.authRegister,
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'preferredLanguage': preferredLanguage,
      },
    );
  }
}
