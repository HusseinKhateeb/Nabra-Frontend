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
      final String host = Uri.base.host.isNotEmpty ? Uri.base.host : '192.168.1.10';
      return '$scheme://$host:8080/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.10:8080/api';
    }

    return 'http://192.168.1.10:8080/api';
  }

  static String get serverBaseUrl {
    final String configured = apiBaseUrl.trim();
    if (configured.endsWith('/api')) {
      return configured.substring(0, configured.length - 4);
    }
    return configured;
  }

  static String get socketBaseUrl => serverBaseUrl;
}
