class ApiEndpoints {
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';

  static const String me = '/users/me';

  static const String sessionsStart = '/sessions/start';
  static const String sessionsStop = '/sessions/stop';
  static const String sessionsHistory = '/sessions/history';

  static const String chats = '/chats';
  static const String messages = '/messages';

  static const String dictionary = '/dictionary';
  static const String learning = '/learning';
  static const String smartPrediction = '/predictions';

<<<<<<< HEAD
  static const String reports = '/reports';
  static const String adminReports = '/admin/reports';
=======
  static const String chats = '/v1/chats';
  static const String messages = '/v1/messages';
  static const String dictionary = '/visual-dictionary';

  static const String learning = '/v1/learning';
  static const String smartPrediction = '/v1/predictions';

  static const String reports = '/v1/reports';
  static const String adminReports = '/v1/admin/reports';
>>>>>>> 8fe1ec9... feat : dictionary
}
