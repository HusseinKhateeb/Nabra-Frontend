import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/auth_session_notifier.dart';
import 'token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  bool _isPublicEndpoint(String path) {
    return path.startsWith('/v1/auth/');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.readAccessToken();
    final bool tokenMissing = token == null || token.isEmpty;
    final bool requiresAuth = !_isPublicEndpoint(options.path);

    if (requiresAuth && tokenMissing) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 401,
            data: 'Missing access token',
          ),
          error: 'Missing access token',
        ),
      );
      return;
    }

    if (!tokenMissing) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    if (kDebugMode && options.path.contains('/v1/lipreading/')) {
      final bool hasAuth = options.headers['Authorization'] != null;
      final String tokenTail =
          (token != null && token.length > 8) ? token.substring(token.length - 8) : (token ?? '');
      debugPrint(
        '[LipReading][Request] ${options.method} ${options.uri} | hasAuth=$hasAuth | tokenTail=$tokenTail',
      );
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final int? status = err.response?.statusCode;
    final String path = err.requestOptions.path;
    final bool protectedEndpoint = !_isPublicEndpoint(path);

    // Clear stale token only on 401 (unauthenticated). Do not clear on 403,
    // because backend endpoint/business errors can surface as 403 on /error.
    if (protectedEndpoint && status == 401) {
      await _tokenStorage.clear();
      authSessionNotifier.markLoggedOut();
      if (kDebugMode) {
        debugPrint('[Auth] Cleared local tokens after $status on $path');
      }
    }

    handler.next(err);
  }
}
