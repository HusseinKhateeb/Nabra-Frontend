import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/token_storage.dart';
import '../domain/session_models.dart';
import 'session_api.dart';

class SessionRepository {
  SessionRepository({
    required SessionApi api,
    required TokenStorage tokenStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage;

  final SessionApi _api;
  final TokenStorage _tokenStorage;

  Future<String> _readRequiredToken() async {
    final String token = (await _tokenStorage.readAccessToken() ?? '').trim();
    if (token.isEmpty) {
      throw const SessionApiException(
        type: SessionApiErrorType.unauthorized,
        message: 'Session expired. Please login again.',
      );
    }
    return token;
  }

  String? _readUserIdFromJwt(String token) {
    try {
      final List<String> parts = token.split('.');
      if (parts.length < 2) return null;
      String payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final Map<String, dynamic> claims =
          jsonDecode(utf8.decode(base64Decode(payload))) as Map<String, dynamic>;
      final dynamic fromUserId = claims['userId'];
      if (fromUserId is String && fromUserId.trim().isNotEmpty) {
        return fromUserId.trim();
      }
      final dynamic fromSub = claims['sub'];
      if (fromSub is String && fromSub.trim().isNotEmpty) {
        return fromSub.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PageResponse<SessionResponse>> getSessions({
    required SessionFilters filters,
    required int page,
    required int size,
    CancelToken? cancelToken,
  }) async {
    final String token = await _readRequiredToken();

    return _api.getSessions(
      filters: filters,
      page: page,
      size: size,
      token: token,
      cancelToken: cancelToken,
    );
  }

  Future<PageResponse<SessionResponse>> getUserAvsrSessions({
    required String userId,
    PageQueryParams params = const PageQueryParams(),
    CancelToken? cancelToken,
  }) async {
    final String token = await _readRequiredToken();
    return _api.getUserAvsrSessions(
      userId: userId,
      params: params,
      token: token,
      cancelToken: cancelToken,
    );
  }

  Future<PageResponse<SessionResponse>> getCurrentUserAvsrSessions({
    PageQueryParams params = const PageQueryParams(),
    CancelToken? cancelToken,
  }) async {
    final String token = await _readRequiredToken();
    final String? userId = _readUserIdFromJwt(token);
    if (userId == null || userId.isEmpty) {
      throw const SessionApiException(
        type: SessionApiErrorType.unknown,
        message: 'Could not resolve current user id from session token.',
      );
    }
    return _api.getUserAvsrSessions(
      userId: userId,
      params: params,
      token: token,
      cancelToken: cancelToken,
    );
  }

  Future<SessionResponse> getSessionById({
    required String sessionId,
    CancelToken? cancelToken,
  }) async {
    final String token = await _readRequiredToken();
    return _api.getSessionById(
      sessionId: sessionId,
      token: token,
      cancelToken: cancelToken,
    );
  }

  Future<void> deleteSession({
    required String sessionId,
    CancelToken? cancelToken,
  }) async {
    final String token = await _readRequiredToken();
    await _api.deleteSession(
      sessionId: sessionId,
      token: token,
      cancelToken: cancelToken,
    );
  }

  Future<void> clearAllSessions({
    CancelToken? cancelToken,
  }) async {
    final String token = await _readRequiredToken();
    await _api.clearAllSessions(
      token: token,
      cancelToken: cancelToken,
    );
  }
}
