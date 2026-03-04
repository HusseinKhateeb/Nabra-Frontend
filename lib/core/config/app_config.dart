class AppConfig {
  /// Android emulator: 10.0.2.2 maps to host machine localhost.
  /// iOS simulator: use http://localhost:8080/api
  static const String apiBaseUrl = String.fromEnvironment(
    'NABRA_API_BASE_URL',
    defaultValue: 'http://192.168.1.8:8080/api', // Use PC Wi-Fi IP for real device testing
    //defaultValue: 'http://10.0.2.2:8080/api', // Android emulator

  );
}
