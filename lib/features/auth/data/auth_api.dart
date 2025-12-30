import 'package:dio/dio.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_tokens.dart';

class AuthApi {
  AuthApi(this._client);

  final DioClient _client;

  // ===============================
  // LOGIN
  // ===============================
  Future<AuthTokens> login({
    required String username,
    required String password,
  }) async {
    final Response res = await _client.dio.post(
      ApiEndpoints.authLogin,
      data: {
        'username': username,
        'password': password,
      },
    );

    return AuthTokens.fromJson(res.data as Map<String, dynamic>);
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
    await _client.dio.post(
      ApiEndpoints.authRegister,
      data: {
        'username': username,
        'email': email,
        'password': password,
        'displayName': displayName,
        'userType': 'USER',
      },
    );
  }

  // ===============================
  // FORGOT PASSWORD
  // ===============================
  Future<void> forgotPassword({
    required String email,
  }) async {
    await _client.dio.post(
      ApiEndpoints.authForgotPassword,
      data: {
        'email': email,
      },
    );
  }

  // ===============================
  // VERIFY RESET CODE
  // ===============================
  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    await _client.dio.post(
      ApiEndpoints.authVerifyResetCode,
      data: {
        'email': email,
        'code': code,
      },
    );
  }

  // ===============================
  // RESET PASSWORD ✅ (المكان الصحيح)
  // ===============================
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.dio.post(
      ApiEndpoints.authResetPassword,
      data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }
}
