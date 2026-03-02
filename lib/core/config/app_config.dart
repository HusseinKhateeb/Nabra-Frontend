class AppConfig {
  /// Android emulator: 10.0.2.2 maps to host machine localhost.
  /// iOS simulator: use http://localhost:8081/api
  static const String apiBaseUrl = String.fromEnvironment(
    'NABRA_API_BASE_URL',
    defaultValue: 'http://localhost:8081/api',
  );
}
