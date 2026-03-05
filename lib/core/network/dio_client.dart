import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

class DioClient {
  DioClient({required TokenStorage tokenStorage})
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(minutes: 5),
            receiveTimeout: const Duration(minutes: 5),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(AuthInterceptor(tokenStorage));
  }

  final Dio dio;
}
