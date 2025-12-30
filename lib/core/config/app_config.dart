import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    return const String.fromEnvironment(
      'NABRA_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080/api',
    );
  }
}
