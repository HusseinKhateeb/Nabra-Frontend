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

  static const String lipReadingInfer = '/v1/lipreading/infer';
  static const String lipReadingAvsrFuse = '/v1/lipreading/avsr/fuse';
  static const String lipReadingAvsrFuseFiles = '/v1/lipreading/avsr/fuse-files';

  static const String reports = '/reports';
  static const String adminReports = '/admin/reports';
}
