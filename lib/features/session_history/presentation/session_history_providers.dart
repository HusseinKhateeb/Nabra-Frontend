import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nabra_frontend/core/providers.dart';
import '../data/mock_session_history.dart';
import '../data/session_history_api.dart';
import '../data/session_history_repository.dart';
import '../domain/session_history_model.dart';

// API Provider
final sessionHistoryApiProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return SessionHistoryApi(dio: dioClient.dio);
});

// Repository Provider
final sessionHistoryRepositoryProvider = Provider((ref) {
  final api = ref.watch(sessionHistoryApiProvider);
  return SessionHistoryRepository(api: api);
});

// Get all session histories
final sessionHistoriesProvider =
    FutureProvider<List<SessionHistory>>((ref) async {
  return MockSessionHistory.getMockSessions();
});

// Get session history by ID
final sessionHistoryByIdProvider =
    FutureProvider.family<SessionHistory, String>((ref, id) async {
  final repository = ref.watch(sessionHistoryRepositoryProvider);
  return repository.getSessionHistoryById(id);
});

// Get session histories by session ID
final sessionHistoriesBySessionIdProvider =
    FutureProvider.family<List<SessionHistory>, String>((ref, sessionId) async {
  final repository = ref.watch(sessionHistoryRepositoryProvider);
  return repository.getAllSessionHistories();
});

// Get statistics
final sessionHistoryStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, sessionId) async {
  final repository = ref.watch(sessionHistoryRepositoryProvider);
  return repository.getStatistics(sessionId);
});

// Pagination
final sessionHistoryPageProvider = StateProvider<int>((ref) => 1);
final sessionHistoryPageSizeProvider = StateProvider<int>((ref) => 20);

// Paginated session histories
final paginatedSessionHistoriesProvider =
    FutureProvider<List<SessionHistory>>((ref) async {
  final repository = ref.watch(sessionHistoryRepositoryProvider);
  final page = ref.watch(sessionHistoryPageProvider);
  final pageSize = ref.watch(sessionHistoryPageSizeProvider);

  return repository.getAllSessionHistories(page: page, pageSize: pageSize);
});
