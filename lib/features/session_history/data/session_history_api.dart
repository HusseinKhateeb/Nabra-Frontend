import 'package:dio/dio.dart';
import 'package:nabra_frontend/core/config/api_endpoints.dart';
import '../domain/session_history_model.dart';

class SessionHistoryApi {
  final Dio dio;

  SessionHistoryApi({required this.dio});

  /// Get all session histories for the current user
  Future<List<SessionHistory>> getAllSessionHistories({
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await dio.get(
        '${ApiEndpoints.sessionsHistory}',
        queryParameters: {
          if (page != null) 'page': page,
          if (pageSize != null) 'pageSize': pageSize,
        },
      );

      final data = response.data as List;
      return data
          .map((json) => SessionHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get session history by ID
  Future<SessionHistory> getSessionHistoryById(String id) async {
    try {
      final response = await dio.get(
        '${ApiEndpoints.sessionsHistory}/$id',
      );
      return SessionHistory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get session histories for a specific session
  Future<List<SessionHistory>> getSessionHistoriesBySessionId(
      String sessionId) async {
    try {
      final response = await dio.get(
        '${ApiEndpoints.sessionsHistory}/session/$sessionId',
      );

      final data = response.data as List;
      return data
          .map((json) => SessionHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a new session history
  Future<SessionHistory> createSessionHistory(
      SessionHistory sessionHistory) async {
    try {
      final response = await dio.post(
        '${ApiEndpoints.sessionsHistory}',
        data: sessionHistory.toJson(),
      );
      return SessionHistory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update session history
  Future<SessionHistory> updateSessionHistory(
      String id, SessionHistory sessionHistory) async {
    try {
      final response = await dio.put(
        '${ApiEndpoints.sessionsHistory}/$id',
        data: sessionHistory.toJson(),
      );
      return SessionHistory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete session history
  Future<void> deleteSessionHistory(String id) async {
    try {
      await dio.delete('${ApiEndpoints.sessionsHistory}/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      return Exception('Failed to fetch session histories: ${e.message}');
    }
    return Exception('An unknown error occurred');
  }
}
