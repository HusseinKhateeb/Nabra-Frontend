import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _envApiBaseUrl =
      String.fromEnvironment('NABRA_API_BASE_URL', defaultValue: '');

  static String get apiBaseUrl {
    if (_envApiBaseUrl.trim().isNotEmpty) {
      return _envApiBaseUrl.trim();
    }

    if (kIsWeb) {
      final String scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
      final String host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return '$scheme://$host:8080/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://localhost:8080/api';
    }

    return 'http://localhost:8080/api';
  }
}
