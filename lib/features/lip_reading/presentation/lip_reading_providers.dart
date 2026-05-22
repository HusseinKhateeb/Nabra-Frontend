import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/lip_reading_api.dart';
import '../data/lip_reading_repository.dart';
import '../domain/avsr_models.dart';
import '../../sessions/data/session_api.dart';
import '../../sessions/data/session_repository.dart';

final lipReadingApiProvider = Provider<LipReadingApi>((ref) {
  return LipReadingApi(ref.watch(dioClientProvider));
});

final _lipReadingSessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(
    api: SessionApi(ref.watch(dioClientProvider).dio),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final lipReadingRepositoryProvider = Provider<LipReadingRepository>((ref) {
  return LipReadingRepository(
    api: ref.watch(lipReadingApiProvider),
    sessionRepository: ref.watch(_lipReadingSessionRepositoryProvider),
  );
});

final lipReadingControllerProvider =
    StateNotifierProvider<LipReadingController, AsyncValue<AvsrFusionResponse?>>((ref) {
  return LipReadingController(ref.watch(lipReadingRepositoryProvider));
});

class LipReadingController extends StateNotifier<AsyncValue<AvsrFusionResponse?>> {
  LipReadingController(this._repo) : super(const AsyncData(null));

  final LipReadingRepository _repo;

  Future<void> runAvsrFusion({
    required File audioFile,
    required File videoFile,
    int frameCount = 25,
    bool fast = false,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.fuseFiles(
        audioFile: audioFile,
        videoFile: videoFile,
        frameCount: frameCount,
        fast: fast,
      ),
    );
  }

  void clearResult() {
    state = const AsyncData(null);
  }
}
