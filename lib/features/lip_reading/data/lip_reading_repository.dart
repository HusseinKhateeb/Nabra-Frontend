import 'dart:io';

import '../../sessions/data/session_repository.dart';
import '../domain/avsr_models.dart';
import 'lip_reading_api.dart';

class LipReadingRepository {
  LipReadingRepository({
    required LipReadingApi api,
    required SessionRepository sessionRepository,
  })  : _api = api,
        _sessionRepository = sessionRepository;

  final LipReadingApi _api;
  final SessionRepository _sessionRepository;

  Future<AvsrFusionResponse> fuseFiles({
    required File audioFile,
    required File videoFile,
    int frameCount = 25,
    bool fast = false,
  }) async {
    final DateTime requestStartedAt = DateTime.now().toUtc();

    try {
      return await _api.fuseFiles(
        audioFile: audioFile,
        videoFile: videoFile,
        frameCount: frameCount,
        fast: fast,
      );
    } catch (error) {
      final String message = error.toString();
      final bool rejectedAudio =
          message.contains('الصوت غير واضح') ||
          message.contains('لم يتم إرجاع الصوت') ||
          message.contains('لم يتم ارجاع الصوت') ||
          message.contains('اشتركوا في القناة');

      if (rejectedAudio) {
        try {
          await _sessionRepository.deleteMostRecentCurrentUserSession(
            createdAfter: requestStartedAt.subtract(
              const Duration(seconds: 10),
            ),
            maxAttempts: 7,
            retryDelay: const Duration(milliseconds: 400),
          );
        } catch (_) {
          // Best-effort cleanup only. Keep the warning visible either way.
        }
      }

      rethrow;
    }
  }
}
