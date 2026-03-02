import '../domain/session_history_model.dart';
import 'session_history_api.dart';

class SessionHistoryRepository {
  final SessionHistoryApi api;

  SessionHistoryRepository({required this.api});

  /// Get all session histories
  Future<List<SessionHistory>> getAllSessionHistories({
    int? page,
    int? pageSize,
  }) async {
    return await api.getAllSessionHistories(page: page, pageSize: pageSize);
  }

  /// Get session history by ID
  Future<SessionHistory> getSessionHistoryById(String id) async {
    return await api.getSessionHistoryById(id);
  }

  /// Get session histories for a specific session
  Future<List<SessionHistory>> getSessionHistoriesBySessionId(
      String sessionId) async {
    return await api.getSessionHistoriesBySessionId(sessionId);
  }

  /// Create a new session history
  Future<SessionHistory> createSessionHistory(
      SessionHistory sessionHistory) async {
    return await api.createSessionHistory(sessionHistory);
  }

  /// Update session history
  Future<SessionHistory> updateSessionHistory(
      String id, SessionHistory sessionHistory) async {
    return await api.updateSessionHistory(id, sessionHistory);
  }

  /// Delete session history
  Future<void> deleteSessionHistory(String id) async {
    return await api.deleteSessionHistory(id);
  }

  /// Get session history statistics
  Future<Map<String, dynamic>> getStatistics(String sessionId) async {
    // This can be extended based on backend capabilities
    final histories = await getSessionHistoriesBySessionId(sessionId);
    return {
      'totalSessions': histories.length,
      'totalDuration': histories.fold<int>(0, (sum, h) => sum + h.duration),
      'averageDuration': histories.isEmpty
          ? 0
          : histories.fold<int>(0, (sum, h) => sum + h.duration) ~/
              histories.length,
      'completedCount': histories.where((h) => h.status == 'COMPLETED').length,
    };
  }
}
