import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/lip_reading_api.dart';
import '../data/lip_reading_repository.dart';
import '../domain/avsr_models.dart';

enum LipReadingPhase { idle, uploading, processing, completed, failed }

final lipReadingApiProvider = Provider<LipReadingApi>((ref) {
  return LipReadingApi(ref.watch(tokenStorageProvider));
});

final lipReadingRepositoryProvider = Provider<LipReadingRepository>((ref) {
  return LipReadingRepository(
    api: ref.watch(lipReadingApiProvider),
  );
});

final lipReadingPhaseProvider =
    StateProvider<LipReadingPhase>((ref) => LipReadingPhase.idle);

final lipReadingControllerProvider =
    StateNotifierProvider<LipReadingController, AsyncValue<AvsrFusionResponse?>>((ref) {
  return LipReadingController(ref, ref.watch(lipReadingRepositoryProvider));
});

class LipReadingController extends StateNotifier<AsyncValue<AvsrFusionResponse?>> {
  LipReadingController(this._ref, this._repo) : super(const AsyncData(null));

  final Ref _ref;
  final LipReadingRepository _repo;
  bool _inFlight = false;

  Future<void> runAvsrFusion({
    required File audioFile,
    required File videoFile,
    int frameCount = 25,
    bool fast = false,
  }) async {
    if (_inFlight) {
      return;
    }
    _inFlight = true;
    state = const AsyncLoading();
    _ref.read(lipReadingPhaseProvider.notifier).state = LipReadingPhase.uploading;

    state = await AsyncValue.guard(
      () => _repo.fuseFiles(
        audioFile: audioFile,
        videoFile: videoFile,
        frameCount: frameCount,
        fast: fast,
        onPhase: (phase) {
          switch (phase.toLowerCase()) {
            case 'uploading':
              _ref.read(lipReadingPhaseProvider.notifier).state =
                  LipReadingPhase.uploading;
              break;
            case 'processing':
              _ref.read(lipReadingPhaseProvider.notifier).state =
                  LipReadingPhase.processing;
              break;
            case 'completed':
              _ref.read(lipReadingPhaseProvider.notifier).state =
                  LipReadingPhase.completed;
              break;
            case 'failed':
              _ref.read(lipReadingPhaseProvider.notifier).state =
                  LipReadingPhase.failed;
              break;
          }
        },
      ),
    );

    if (state.hasError) {
      _ref.read(lipReadingPhaseProvider.notifier).state = LipReadingPhase.failed;
    } else {
      _ref.read(lipReadingPhaseProvider.notifier).state =
          LipReadingPhase.completed;
    }
    _inFlight = false;
  }

  void clearResult() {
    state = const AsyncData(null);
    _ref.read(lipReadingPhaseProvider.notifier).state = LipReadingPhase.idle;
  }
}
