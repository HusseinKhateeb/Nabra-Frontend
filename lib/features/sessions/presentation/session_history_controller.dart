import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../data/session_api.dart';
import '../data/session_repository.dart';
import '../domain/session_models.dart';

final sessionApiProvider = Provider<SessionApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SessionApi(dioClient.dio);
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    api: ref.watch(sessionApiProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final sessionHistoryControllerProvider =
    StateNotifierProvider<SessionHistoryController, SessionHistoryState>((ref) {
  final SessionHistoryController controller = SessionHistoryController(
    ref: ref,
    repository: ref.watch(sessionRepositoryProvider),
  );
  controller.fetchSessions();
  return controller;
});

class SessionHistoryState {
  const SessionHistoryState({
    required this.sessions,
    required this.filters,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.loading,
    this.error,
    this.lastErrorType,
  });

  final List<SessionResponse> sessions;
  final SessionFilters filters;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool loading;
  final String? error;
  final SessionApiErrorType? lastErrorType;

  SessionHistoryState copyWith({
    List<SessionResponse>? sessions,
    SessionFilters? filters,
    int? page,
    int? size,
    int? totalPages,
    int? totalElements,
    bool? loading,
    String? error,
    bool clearError = false,
    SessionApiErrorType? lastErrorType,
  }) {
    return SessionHistoryState(
      sessions: sessions ?? this.sessions,
      filters: filters ?? this.filters,
      page: page ?? this.page,
      size: size ?? this.size,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      lastErrorType: clearError ? null : (lastErrorType ?? this.lastErrorType),
    );
  }

  static const SessionHistoryState initial = SessionHistoryState(
    sessions: <SessionResponse>[],
    filters: SessionFilters.initial,
    page: 0,
    size: 10,
    totalPages: 0,
    totalElements: 0,
    loading: false,
  );
}

class SessionHistoryController extends StateNotifier<SessionHistoryState> {
  SessionHistoryController({
    required Ref ref,
    required SessionRepository repository,
  })  : _ref = ref,
        _repository = repository,
        super(SessionHistoryState.initial);

  final Ref _ref;
  final SessionRepository _repository;
  CancelToken? _cancelToken;
  int _requestCounter = 0;

  Future<void> fetchSessions() async {
    await _fetchInternal();
  }

  Future<void> refresh() async {
    await _fetchInternal();
  }

  Future<void> fetchUserAvsrSessions(
    String userId, {
    int page = 0,
    int size = 10,
    String sort = 'startedAt,desc',
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final PageResponse<SessionResponse> response =
          await _repository.getUserAvsrSessions(
        userId: userId,
        params: PageQueryParams(page: page, size: size, sort: sort),
      );

      state = state.copyWith(
        sessions: response.content,
        totalPages: response.totalPages,
        totalElements: response.totalElements,
        page: response.number,
        size: response.size,
        loading: false,
        clearError: true,
      );
    } on SessionApiException catch (e) {
      if (e.type == SessionApiErrorType.unauthorized) {
        await _ref.read(tokenStorageProvider).clear();
        appRouter.go(AppRoutes.login);
      }
      state = state.copyWith(
        loading: false,
        error: e.message,
        lastErrorType: e.type,
      );
    }
  }

  Future<SessionResponse?> getSessionById(String sessionId) async {
    try {
      return await _repository.getSessionById(sessionId: sessionId);
    } on SessionApiException catch (e) {
      if (e.type == SessionApiErrorType.unauthorized) {
        await _ref.read(tokenStorageProvider).clear();
        appRouter.go(AppRoutes.login);
      }
      state = state.copyWith(error: e.message, lastErrorType: e.type);
      return null;
    }
  }

  Future<bool> deleteSession(String sessionId) async {
    try {
      await _repository.deleteSession(sessionId: sessionId);

      final List<SessionResponse> updated = state.sessions
          .where((SessionResponse item) => item.id != sessionId)
          .toList(growable: false);
      final int nextTotal = (state.totalElements - 1).clamp(0, 1 << 30);
      final int nextPages = nextTotal == 0 ? 0 : ((nextTotal - 1) ~/ state.size) + 1;

      state = state.copyWith(
        sessions: updated,
        totalElements: nextTotal,
        totalPages: nextPages,
        clearError: true,
      );

      if (updated.isEmpty && state.page > 0) {
        await setPage(state.page - 1);
      }

      return true;
    } on SessionApiException catch (e) {
      if (e.type == SessionApiErrorType.unauthorized) {
        await _ref.read(tokenStorageProvider).clear();
        appRouter.go(AppRoutes.login);
      }
      state = state.copyWith(error: e.message, lastErrorType: e.type);
      return false;
    }
  }

  Future<bool> clearAllSessions() async {
    try {
      await _repository.clearAllSessions();
      state = state.copyWith(
        sessions: const <SessionResponse>[],
        totalElements: 0,
        totalPages: 0,
        page: 0,
        clearError: true,
      );
      return true;
    } on SessionApiException catch (e) {
      if (e.type == SessionApiErrorType.unauthorized) {
        await _ref.read(tokenStorageProvider).clear();
        appRouter.go(AppRoutes.login);
        return false;
      }

      final bool fallbackCleared = await _fallbackClearByDeletingEachSession();
      if (fallbackCleared) {
        state = state.copyWith(
          sessions: const <SessionResponse>[],
          totalElements: 0,
          totalPages: 0,
          page: 0,
          clearError: true,
        );
        return true;
      }

      state = state.copyWith(error: e.message, lastErrorType: e.type);
      return false;
    }
  }

  Future<bool> _fallbackClearByDeletingEachSession() async {
    try {
      const int pageSize = 50;
      int safetyRounds = 0;

      // Always read page 0 because deleting entries shifts pagination.
      while (safetyRounds < 100) {
        final PageResponse<SessionResponse> page =
            await _repository.getCurrentUserAvsrSessions(
          params: const PageQueryParams(page: 0, size: pageSize, sort: 'startedAt,desc'),
        );

        if (page.content.isEmpty) {
          return true;
        }

        for (final SessionResponse session in page.content) {
          await _repository.deleteSession(sessionId: session.id);
        }

        safetyRounds++;
      }

      return false;
    } on SessionApiException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setPage(int page) async {
    if (page < 0) return;
    if (state.totalPages > 0 && page >= state.totalPages) return;
    state = state.copyWith(page: page);
    await _fetchInternal();
  }

  Future<void> setSize(int size) async {
    if (size <= 0) return;
    state = state.copyWith(size: size, page: 0);
    await _fetchInternal();
  }

  Future<void> updateFilters(
    Map<String, dynamic> partial,
  ) async {
    final SessionFilters nextFilters = _mergeFilters(state.filters, partial);

    state = state.copyWith(filters: nextFilters, page: 0);

    await _fetchInternal();
  }

  Future<void> resetFilters() async {
    state = state.copyWith(filters: SessionFilters.initial, page: 0);
    await _fetchInternal();
  }

  Future<void> _fetchInternal() async {
    final int requestId = ++_requestCounter;
    _cancelToken?.cancel('A new sessions request started.');
    _cancelToken = CancelToken();

    state = state.copyWith(loading: true, clearError: true);

    try {
      final PageResponse<SessionResponse> response = await _repository.getSessions(
        filters: state.filters,
        page: state.page,
        size: state.size,
        cancelToken: _cancelToken,
      );

      if (requestId != _requestCounter) {
        return;
      }

      state = state.copyWith(
        sessions: response.content,
        totalPages: response.totalPages,
        totalElements: response.totalElements,
        page: response.number,
        size: response.size,
        loading: false,
        clearError: true,
      );
    } on SessionApiException catch (e) {
      if (requestId != _requestCounter) {
        return;
      }

      final bool optionalParamBackendIssue = e.type == SessionApiErrorType.badRequest &&
          e.message.toLowerCase().contains('java.util.optional');

      if (optionalParamBackendIssue) {
        try {
          final PageResponse<SessionResponse> fallback =
              await _repository.getCurrentUserAvsrSessions(
            params: PageQueryParams(
              page: state.page,
              size: state.size,
              sort: state.filters.sort,
            ),
            cancelToken: _cancelToken,
          );

          if (requestId != _requestCounter) {
            return;
          }

          state = state.copyWith(
            sessions: fallback.content,
            totalPages: fallback.totalPages,
            totalElements: fallback.totalElements,
            page: fallback.number,
            size: fallback.size,
            loading: false,
            clearError: true,
          );
          return;
        } on SessionApiException catch (fallbackError) {
          state = state.copyWith(
            loading: false,
            error: fallbackError.message,
            lastErrorType: fallbackError.type,
          );
          return;
        }
      }

      if (e.type == SessionApiErrorType.unauthorized) {
        await _ref.read(tokenStorageProvider).clear();
        appRouter.go(AppRoutes.login);
      }

      state = state.copyWith(
        loading: false,
        error: e.message,
        lastErrorType: e.type,
      );
    } catch (_) {
      if (requestId != _requestCounter) {
        return;
      }
      state = state.copyWith(
        loading: false,
        error: 'Could not load sessions. Please try again.',
        lastErrorType: SessionApiErrorType.unknown,
      );
    }
  }

  SessionFilters _mergeFilters(SessionFilters current, Map<String, dynamic> partial) {
    final bool clearFrom = partial.containsKey('from') && partial['from'] == null;
    final bool clearTo = partial.containsKey('to') && partial['to'] == null;
    final bool clearMinDuration =
        partial.containsKey('minDuration') && partial['minDuration'] == null;
    final bool clearMaxDuration =
        partial.containsKey('maxDuration') && partial['maxDuration'] == null;

    return current.copyWith(
      from: partial['from'] as DateTime?,
      to: partial['to'] as DateTime?,
      minDuration: partial['minDuration'] as int?,
      maxDuration: partial['maxDuration'] as int?,
      sort: partial['sort'] as String?,
      clearFrom: clearFrom,
      clearTo: clearTo,
      clearMinDuration: clearMinDuration,
      clearMaxDuration: clearMaxDuration,
    );
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Controller disposed');
    super.dispose();
  }
}
