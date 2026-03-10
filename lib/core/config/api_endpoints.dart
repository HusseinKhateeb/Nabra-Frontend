  class ApiEndpoints {
    static String chatVoiceMessage(String chatId) => '$_v1/chats/$chatId/voice-message';
    static const String chatVoiceInfer = '$_v1/chats/voice-infer';
  static const String _v1 = '/v1';

  // Auth
  static const String authRegister = '$_v1/auth/register';
  static const String authLogin = '$_v1/auth/login';
  static const String authChangePassword = '$_v1/auth/change-password';
  static const String authForgotPassword = '$_v1/auth/forgot-password';
  static const String authVerifyResetCode = '$_v1/auth/verify-reset-code';
  static const String authResetPassword = '$_v1/auth/reset-password';
  static const String authGoogle = '$_v1/auth/google';

  // Users
  static const String usersMe = '$_v1/users/me';
  static const String users = '$_v1/users';
  static const String usersProfile = '$_v1/users/profile';
  static const String usersSettings = '$_v1/users/settings';

  // Chat & Messages
  static const String chats = '$_v1/chats';

  // Sessions
  static const String sessions = '$_v1/sessions';

  // Smart prediction
  static const String predictionNext = '$_v1/prediction/next';
  static const String predictionCorrect = '$_v1/prediction/correct';

  // Reports
  static const String reports = '$_v1/reports';

  // Admin
  static const String adminUsers = '$_v1/admin/users';
  static const String adminReports = '$_v1/admin/reports';

  // Visual dictionary (non-v1 API prefix by backend design)
  static const String dictionary = '/visual-dictionary';
  static const String adminDictionary = '/admin/visual-dictionary';

  // Lip reading
  static const String lipReadingPing = '$_v1/lipreading/ping';
  static const String lipReadingInfer = '$_v1/lipreading/infer';
  static const String lipReadingAvsrFuse = '$_v1/lipreading/avsr/fuse';
  static const String lipReadingAvsrFuseFiles =
    '$_v1/lipreading/avsr/fuse-files';
  static const String lipReadingAvsrUploadAudio =
    '$_v1/lipreading/avsr/upload-audio';
  static const String lipReadingAvsrUploadVideo =
    '$_v1/lipreading/avsr/upload-video';

  static String chatMessages(String chatId) => '$chats/$chatId/messages';

  static String chatById(String chatId) => '$chats/$chatId';

  static String sessionStop(String sessionId) => '$sessions/$sessionId/stop';

  static String sessionById(String sessionId) => '$sessions/$sessionId';

  static String userAvsrSessions(String userId) => '$_v1/$userId/sessions/';

  static String adminReportById(String reportId) => '$adminReports/$reportId';

  static String dictionaryCategoryWords(String categoryId) =>
    '$dictionary/categories/$categoryId/words';

  static String dictionaryFavoriteWord(String wordId) =>
    '$dictionary/favorites/$wordId';

  static String lipReadingAvsrFuseFilesStatus(String jobId) =>
    '$lipReadingAvsrFuseFiles/status/$jobId';
}
