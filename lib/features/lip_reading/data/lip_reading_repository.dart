import 'dart:io';

import '../domain/avsr_models.dart';
import 'lip_reading_api.dart';

class LipReadingRepository {
  LipReadingRepository({required LipReadingApi api}) : _api = api;

  final LipReadingApi _api;

  Future<AvsrFusionResponse> fuseFiles({
    required File audioFile,
    required File videoFile,
    int frameCount = 25,
    bool fast = false,
  }) {
    return _api.fuseFiles(
      audioFile: audioFile,
      videoFile: videoFile,
      frameCount: frameCount,
      fast: fast,
    );
  }
}
