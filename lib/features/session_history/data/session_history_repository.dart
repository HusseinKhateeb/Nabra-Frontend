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

  /// Get session history by session ID (alias)
  Future<SessionHistory> getSessionHistoryBySessionId(String sessionId) async {
    return await api.getSessionHistoryBySessionId(sessionId);
  }

  /// Get session histories with filters
  Future<List<SessionHistory>> getSessionHistoriesWithFilters({
    String? inputType,
    String? outputType,
    String? status,
    String? keyword,
    int? minDuration,
    int? maxDuration,
    String? from,
    String? to,
    int? page,
    int? pageSize,
    String? sort,
  }) async {
    return await api.getSessionHistoriesWithFilters(
      inputType: inputType,
      outputType: outputType,
      status: status,
      keyword: keyword,
      minDuration: minDuration,
      maxDuration: maxDuration,
      from: from,
      to: to,
      page: page,
      pageSize: pageSize,
      sort: sort,
    );
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
    final history = await getSessionHistoryBySessionId(sessionId);
    return {
      'sessionId': history.sessionId,
      'durationSeconds': history.durationSeconds,
      'status': history.status,
    };
  }
}
