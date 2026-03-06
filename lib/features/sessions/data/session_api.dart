import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/api_endpoints.dart';
import '../domain/session_models.dart';

enum SessionApiErrorType {
  unauthorized,
  forbidden,
  badRequest,
  server,
  network,
  unknown,
}

class SessionApiException implements Exception {
  const SessionApiException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final SessionApiErrorType type;
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class SessionApi {
  SessionApi(this._dio);

  final Dio _dio;

  Future<PageResponse<SessionResponse>> getSessions({
    required SessionFilters filters,
    required int page,
    required int size,
    required String token,
    CancelToken? cancelToken,
  }) async {
    final Map<String, dynamic> params = _buildSessionQueryParams(
      filters: filters,
      page: page,
      size: size,
    );

    try {
      final Response<dynamic> response = await _dio.get(
        ApiEndpoints.sessions,
        queryParameters: params,
        cancelToken: cancelToken,
        options: Options(headers: <String, String>{
          'Authorization': 'Bearer $token',
        }),
      );

      final dynamic payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw const SessionApiException(
          type: SessionApiErrorType.unknown,
          message: 'Unexpected sessions response format.',
        );
      }

      return PageResponse<SessionResponse>.fromJson(
        payload,
        SessionResponse.fromJson,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on SessionApiException {
      rethrow;
    } catch (_) {
      throw const SessionApiException(
        type: SessionApiErrorType.unknown,
        message: 'Failed to fetch sessions due to an unknown error.',
      );
    }
  }

  Future<PageResponse<SessionResponse>> getUserAvsrSessions({
    required String userId,
    required PageQueryParams params,
    required String token,
    CancelToken? cancelToken,
  }) async {
    final String cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      throw const SessionApiException(
        type: SessionApiErrorType.badRequest,
        message: 'User id is required.',
      );
    }

    final Map<String, dynamic> query = <String, dynamic>{
      'page': params.page,
      'size': params.size,
      'sort': params.sort,
    };

    try {
      final Response<dynamic> response = await _dio.get(
        ApiEndpoints.userAvsrSessions(cleanUserId),
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(headers: <String, String>{
          'Authorization': 'Bearer $token',
        }),
      );

      final dynamic payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw const SessionApiException(
          type: SessionApiErrorType.unknown,
          message: 'Unexpected sessions response format.',
        );
      }

      return PageResponse<SessionResponse>.fromJson(
        payload,
        SessionResponse.fromJson,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on SessionApiException {
      rethrow;
    } catch (_) {
      throw const SessionApiException(
        type: SessionApiErrorType.unknown,
        message: 'Failed to fetch sessions due to an unknown error.',
      );
    }
  }

  Future<SessionResponse> getSessionById({
    required String sessionId,
    required String token,
    CancelToken? cancelToken,
  }) async {
    final String cleanSessionId = sessionId.trim();
    if (cleanSessionId.isEmpty) {
      throw const SessionApiException(
        type: SessionApiErrorType.badRequest,
        message: 'Session id is required.',
      );
    }

    try {
      final Response<dynamic> response = await _dio.get(
        ApiEndpoints.sessionById(cleanSessionId),
        cancelToken: cancelToken,
        options: Options(headers: <String, String>{
          'Authorization': 'Bearer $token',
        }),
      );

      final dynamic payload = response.data;
      if (payload is! Map<String, dynamic>) {
        throw const SessionApiException(
          type: SessionApiErrorType.unknown,
          message: 'Unexpected session details response format.',
        );
      }
      return SessionResponse.fromJson(payload);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> deleteSession({
    required String sessionId,
    required String token,
    CancelToken? cancelToken,
  }) async {
    final String cleanSessionId = sessionId.trim();
    if (cleanSessionId.isEmpty) {
      throw const SessionApiException(
        type: SessionApiErrorType.badRequest,
        message: 'Session id is required.',
      );
    }

    try {
      final Uri url = Uri.parse(
        '${AppConfig.apiBaseUrl}${ApiEndpoints.sessionById(cleanSessionId)}',
      );

      final Response<dynamic> response = await _dio.deleteUri(
        url,
        cancelToken: cancelToken,
        options: Options(headers: <String, String>{
          'Authorization': 'Bearer $token',
        }),
      );

      if (kDebugMode) {
        debugPrint('[Sessions][DeleteOne] DELETE $url -> ${response.statusCode}');
      }

      final int? code = response.statusCode;
      if (code != 204 && code != 200) {
        throw SessionApiException(
          type: SessionApiErrorType.unknown,
          statusCode: code,
          message: 'Delete session failed (status: $code).',
        );
      }
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> clearAllSessions({
    required String token,
    CancelToken? cancelToken,
  }) async {
    try {
      final Uri url = Uri.parse(
        '${AppConfig.apiBaseUrl}${ApiEndpoints.sessions}?confirm=true',
      );

      final Response<dynamic> response = await _dio.deleteUri(
        url,
        cancelToken: cancelToken,
        options: Options(headers: <String, String>{
          'Authorization': 'Bearer $token',
        }),
      );

      if (kDebugMode) {
        debugPrint('[Sessions][ClearAll] DELETE $url -> ${response.statusCode}');
      }

      final int? code = response.statusCode;
      if (code != 204 && code != 200) {
        throw SessionApiException(
          type: SessionApiErrorType.unknown,
          statusCode: code,
          message: 'Clear sessions failed (status: $code).',
        );
      }
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Map<String, dynamic> _buildSessionQueryParams({
    required SessionFilters filters,
    required int page,
    required int size,
  }) {
    return <String, dynamic>{
      'page': page,
      'size': size,
      'sort': filters.sort,
      if (filters.from != null) 'from': filters.from!.toUtc().toIso8601String(),
      if (filters.to != null) 'to': filters.to!.toUtc().toIso8601String(),
      if (filters.minDuration != null) 'minDuration': filters.minDuration,
      if (filters.maxDuration != null) 'maxDuration': filters.maxDuration,
    };
  }

  SessionApiException _mapDioError(DioException e) {
    final int? statusCode = e.response?.statusCode;
    final String responseMessage = _extractMessage(e.response?.data);

    if (e.type == DioExceptionType.cancel) {
      return const SessionApiException(
        type: SessionApiErrorType.network,
        message: 'Request was canceled.',
      );
    }

    if (statusCode == 401) {
      return SessionApiException(
        type: SessionApiErrorType.unauthorized,
        statusCode: statusCode,
        message: 'Session expired. Please login again.',
      );
    }

    if (statusCode == 403) {
      return SessionApiException(
        type: SessionApiErrorType.forbidden,
        statusCode: statusCode,
        message: responseMessage.isEmpty
            ? 'You are not allowed to access these sessions.'
            : responseMessage,
      );
    }

    if (statusCode == 400) {
      return SessionApiException(
        type: SessionApiErrorType.badRequest,
        statusCode: statusCode,
        message: responseMessage.isEmpty
            ? 'Some filters are invalid. Please check your input.'
            : responseMessage,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return SessionApiException(
        type: SessionApiErrorType.server,
        statusCode: statusCode,
        message: 'Server is unavailable right now. Please try again.',
      );
    }

    if (e.error is SocketException ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const SessionApiException(
        type: SessionApiErrorType.network,
        message: 'Network error while loading sessions. Check your connection.',
      );
    }

    return SessionApiException(
      type: SessionApiErrorType.unknown,
      statusCode: statusCode,
      message: responseMessage.isEmpty
          ? 'Could not load sessions. Please try again.'
          : responseMessage,
    );
  }

  String _extractMessage(dynamic data) {
    if (data == null) return '';
    if (data is String) return data.trim();
    if (data is Map<String, dynamic>) {
      for (final String key in <String>['message', 'error', 'detail', 'title']) {
        final dynamic value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return data.toString();
    }
    return data.toString();
  }
}
