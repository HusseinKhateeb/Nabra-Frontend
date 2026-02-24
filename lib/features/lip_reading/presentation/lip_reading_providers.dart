import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/lip_reading_api.dart';
import '../data/lip_reading_repository.dart';
import '../domain/avsr_models.dart';

final lipReadingApiProvider = Provider<LipReadingApi>((ref) {
  return LipReadingApi(ref.watch(dioClientProvider));
});

final lipReadingRepositoryProvider = Provider<LipReadingRepository>((ref) {
  return LipReadingRepository(
    api: ref.watch(lipReadingApiProvider),
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
    int topK = 5,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.fuseFiles(
        audioFile: audioFile,
        videoFile: videoFile,
        topK: topK,
      ),
    );
  }

  void clearResult() {
    state = const AsyncData(null);
  }
}
