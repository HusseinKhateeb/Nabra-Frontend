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
        ApiEndpoints.sessionsHistory,
        queryParameters: {
          if (page != null) 'page': page,
          if (pageSize != null) 'size': pageSize,
        },
      );

      final payload = response.data;
      final data = payload is Map<String, dynamic>
          ? (payload['content'] as List? ?? const <dynamic>[])
          : (payload as List? ?? const <dynamic>[]);
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
    try {
      final response = await dio.get(
        ApiEndpoints.sessionsHistory,
        queryParameters: {
          if (inputType != null) 'inputType': inputType,
          if (outputType != null) 'outputType': outputType,
          if (status != null) 'status': status,
          if (keyword != null) 'keyword': keyword,
          if (minDuration != null) 'minDuration': minDuration,
          if (maxDuration != null) 'maxDuration': maxDuration,
          if (from != null) 'from': from,
          if (to != null) 'to': to,
          if (page != null) 'page': page,
          if (pageSize != null) 'size': pageSize,
          if (sort != null) 'sort': sort,
        },
      );

      final payload = response.data;
      final data = payload is Map<String, dynamic>
          ? (payload['content'] as List? ?? const <dynamic>[])
          : (payload as List? ?? const <dynamic>[]);
      return data
          .map((json) => SessionHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get single session history by ID (alias)
  Future<SessionHistory> getSessionHistoryBySessionId(String sessionId) async {
    return getSessionHistoryById(sessionId);
  }

  /// Create a new session (start session)
  Future<SessionHistory> createSessionHistory(
      SessionHistory sessionHistory) async {
    try {
      final response = await dio.post(
        ApiEndpoints.sessionsStart,
        data: sessionHistory.toStartRequestJson(),
      );
      return SessionHistory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Stop a session
  Future<SessionHistory> updateSessionHistory(
      String id, SessionHistory sessionHistory) async {
    try {
      final response = await dio.post(
        '${ApiEndpoints.sessionsStop}/$id/stop',
        data: sessionHistory.toStopRequestJson(),
      );
      return SessionHistory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete session history
  Future<void> deleteSessionHistory(String id) async {
    try {
      await dio.delete('${ApiEndpoints.sessions}/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      final responseBody = e.response?.data;
      return Exception(
        'Failed to fetch session histories: ${e.message} (status: $statusCode, response: $responseBody)',
      );
    }
    return Exception('An unknown error occurred');
  }
}
