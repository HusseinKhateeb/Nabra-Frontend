class ApiEndpoints {
  static const String authRegister = '/v1/auth/register';
  static const String authLogin = '/v1/auth/login';

  // 🔐 Google Auth
  static const String authGoogle = '/v1/auth/google';

  static const String authForgotPassword = '/v1/auth/forgot-password';
  static const String authVerifyResetCode = '/v1/auth/verify-reset-code';
  static const String authResetPassword = '/v1/auth/reset-password';

  static const String me = '/v1/users/me';

  static const String sessionsStart = '/v1/sessions/start';
  static const String sessionsStop = '/v1/sessions/stop';
  static const String sessionsHistory = '/v1/sessions/history';

  static const String chats = '/v1/chats';
  static const String messages = '/v1/messages';
  static const String dictionary = '/visual-dictionary';

  static const String learning = '/v1/learning';
  static const String smartPrediction = '/v1/predictions';

  static const String reports = '/v1/reports';
  static const String adminReports = '/v1/admin/reports';
}
