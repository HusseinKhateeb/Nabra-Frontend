import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../domain/avsr_models.dart';
import 'lip_reading_providers.dart';

// Dark red theme colors
const Color _darkRed = Color(0xFF8B0000);
const Color _lightRed = Color(0xFFDC143C);
const Color _black = Color(0xFF222222);
const Color _grey = Color(0xFFEEEEEE);
const Color _cardBg = Color(0xFFF8F8F8);

const int _videoCaptureDurationMs = 1000;
const int _audioCaptureDurationMs = 1000;
const int _capturedFrameTarget = 25;
const int _targetBackendFrames = 25;
const int _recordingFps = 25;
const double _estimatedCaptureFps = 25.0;
const double _audioBoostGain = 1.8;
const int _wavHeaderSize = 44;
const int _frameTolerance = 1;

class LipReadingPage extends ConsumerStatefulWidget {
  const LipReadingPage({super.key});

  @override
  ConsumerState<LipReadingPage> createState() => _LipReadingPageState();
}

class _LipReadingPageState extends ConsumerState<LipReadingPage> {
  CameraController? _controller;
  final AudioRecorder _audioRecorder = AudioRecorder();
  ResolutionPreset _activeResolutionPreset = ResolutionPreset.medium;

  bool _initializing = true;
  bool _isCapturing = false;
  String _captureStatus = 'Ready';

  bool get _isSupportedPlatform {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _isMobilePlatform {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    if (!_isSupportedPlatform) {
      _initializing = false;
      return;
    }
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final List<ResolutionPreset> preferredPresets = <ResolutionPreset>[
        // ResolutionPreset.veryHigh,
        ResolutionPreset.high,
        ResolutionPreset.medium,
      ];

      CameraController? selectedController;
      ResolutionPreset selectedPreset = ResolutionPreset.medium;

      for (final preset in preferredPresets) {
        final candidate = CameraController(
          front,
          preset,
          enableAudio: false,
          fps: _recordingFps,
        );
        try {
          await candidate.initialize();
          try {
            await candidate.prepareForVideoRecording();
          } catch (_) {
            // Some devices/platforms may not require or support this optimization.
          }
          await _warmupVideoRecorder(candidate);
          selectedController = candidate;
          selectedPreset = preset;
          break;
        } catch (_) {
          await candidate.dispose();
        }
      }

      if (selectedController == null) {
        throw Exception('Unable to initialize camera with supported resolution.');
      }

      if (!mounted) return;
      setState(() {
        _controller = selectedController;
        _activeResolutionPreset = selectedPreset;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _initializing = false);
    }
  }

  Future<void> _warmupVideoRecorder(CameraController controller) async {
    if (kIsWeb) return;
    try {
      await controller.startVideoRecording();
      await Future<void>.delayed(const Duration(milliseconds: 180));
      final XFile stoppedFile = await controller.stopVideoRecording();
      final String warmupPath = stoppedFile.path;
      if (warmupPath.isNotEmpty) {
        final File warmupFile = File(warmupPath);
        if (await warmupFile.exists()) {
          await warmupFile.delete();
        }
      }
      try {
        await controller.prepareForVideoRecording();
      } catch (_) {
        // best-effort re-prepare
      }
    } catch (_) {
      // warm-up is best-effort only
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<File> _buildBoostedAudioBuffer({
    required File sourceFile,
    required Directory tempDir,
    double gain = _audioBoostGain,
  }) async {
    final Uint8List bytes = await sourceFile.readAsBytes();
    if (bytes.length <= _wavHeaderSize) {
      return sourceFile;
    }

    final String riff = String.fromCharCodes(bytes.sublist(0, 4));
    final String wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') {
      return sourceFile;
    }

    final ByteData sourceData = ByteData.sublistView(bytes);
    final Uint8List boostedBytes = Uint8List.fromList(bytes);
    final ByteData boostedData = ByteData.sublistView(boostedBytes);

    for (int offset = _wavHeaderSize; offset + 1 < boostedBytes.length; offset += 2) {
      final int sample = sourceData.getInt16(offset, Endian.little);
      final int amplified = (sample * gain).round().clamp(-32768, 32767);
      boostedData.setInt16(offset, amplified, Endian.little);
    }

    final String boostedPath =
        '${tempDir.path}/audio-boosted-${DateTime.now().millisecondsSinceEpoch}.wav';
    final File boostedFile = File(boostedPath);
    await boostedFile.writeAsBytes(boostedBytes, flush: true);
    return boostedFile;
  }

  Future<void> _startCaptureAndSend() async {
    if (_isCapturing) {
      return;
    }

    final CameraController? camera = _controller;
    if (camera == null || !camera.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera is not ready yet.')),
      );
      return;
    }

    ref.read(lipReadingControllerProvider.notifier).clearResult();
    setState(() {
      _isCapturing = true;
      _captureStatus = 'Recording started...';
    });

    late XFile recordedVideo;
    String? recordedAudio;
    final DateTime startedAt = DateTime.now();

    try {
      if (kIsWeb) {
        setState(() {
          _isCapturing = false;
          _captureStatus = 'AVSR requires both audio and video.';
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This AVSR flow currently requires audio + video and is not supported on web.'),
          ),
        );
        return;
      } else {
        // Mobile: Record audio and video
        final bool hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required.')),
          );
          return;
        }

        final Directory tempDir = await getTemporaryDirectory();
        final String audioPath =
            '${tempDir.path}/audio-${DateTime.now().millisecondsSinceEpoch}.wav';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: audioPath,
        );
        setState(() {
          _captureStatus = 'Collecting raw $_capturedFrameTarget frames ($_videoCaptureDurationMs ms @ ${_recordingFps}fps, $_activeResolutionPreset)...';
        });

        try {
          await camera.prepareForVideoRecording();
        } catch (_) {
          // best-effort pre-prepare right before recording
        }
        await camera.startVideoRecording();
        final DateTime videoStartedAt = DateTime.now();
        await Future<void>.delayed(const Duration(milliseconds: _videoCaptureDurationMs));
        recordedVideo = await camera.stopVideoRecording();
        final int actualVideoDurationMs = DateTime.now().difference(videoStartedAt).inMilliseconds;
        final int estimatedFramesSent = ((actualVideoDurationMs / 1000) * _estimatedCaptureFps).round();

        if (mounted) {
          setState(() {
            _captureStatus = 'Video captured (~$estimatedFramesSent frames). Continuing audio...';
          });
        }

        final int elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
        final int remainingAudioMs = _audioCaptureDurationMs - elapsedMs;
        if (remainingAudioMs > 0) {
          await Future<void>.delayed(Duration(milliseconds: remainingAudioMs));
        }

        recordedAudio = await _audioRecorder.stop();

        if (mounted) {
          setState(() {
            _captureStatus = 'Enhancing audio buffer...';
          });
        }

        // Check audio file
        if (recordedAudio == null || recordedAudio.isEmpty) {
          setState(() {
            _isCapturing = false;
            _captureStatus = 'Audio recording failed.';
          });
          return;
        }
        // Check video file
        if (recordedVideo.path.isEmpty || !(await File(recordedVideo.path).exists())) {
          setState(() {
            _isCapturing = false;
            _captureStatus = 'Video recording failed.';
          });
          return;
        }

        final audioFile = File(recordedAudio);
        final File boostedAudioFile = await _buildBoostedAudioBuffer(
          sourceFile: audioFile,
          tempDir: tempDir,
        );
        if (mounted) {
          setState(() {
            _captureStatus = 'Uploading to backend...';
          });
        }
        // Keep mp4 name for backend compatibility; try fast rename first.
        final mp4VideoPath = '${tempDir.path}/video-${DateTime.now().millisecondsSinceEpoch}.mp4';
        File videoFile;
        try {
          videoFile = await File(recordedVideo.path).rename(mp4VideoPath);
        } catch (_) {
          videoFile = await File(recordedVideo.path).copy(mp4VideoPath);
        }
        final audioExists = await boostedAudioFile.exists();
        final videoExists = await videoFile.exists();
        final audioSize = audioExists ? await boostedAudioFile.length() : 0;
        final videoSize = videoExists ? await videoFile.length() : 0;
        final audioExt = boostedAudioFile.path.split('.').last;
        final videoExt = videoFile.path.split('.').last;
        debugPrint('Audio file: path=${boostedAudioFile.path}, exists=$audioExists, size=${audioSize} bytes, ext=$audioExt, gain=$_audioBoostGain');
        debugPrint('Video file: path=${videoFile.path}, exists=$videoExists, size=${videoSize} bytes, ext=$videoExt');
        debugPrint('Capture profile -> video=${actualVideoDurationMs}ms, audioTarget=${_audioCaptureDurationMs}ms, capturedFramesTarget=$_capturedFrameTarget, backendFramesTarget=$_targetBackendFrames');
        debugPrint('Estimated raw captured frames: ~$estimatedFramesSent (estFPS=$_estimatedCaptureFps)');
        if ((estimatedFramesSent - _capturedFrameTarget).abs() > _frameTolerance) {
          debugPrint('[WARNING] Estimated raw frames ($estimatedFramesSent) differ from target ($_capturedFrameTarget).');
        }
        await ref.read(lipReadingControllerProvider.notifier).runAvsrFusion(
          audioFile: boostedAudioFile,
          videoFile: videoFile,
          frameCount: _targetBackendFrames,
          fast: false,
        );
      }

      if (!mounted) return;
      setState(() {
        _captureStatus = 'Done';
      });
    } catch (e) {
      if (!kIsWeb) {
        await _audioRecorder.stop();
        if (camera.value.isRecordingVideo) {
          await camera.stopVideoRecording();
        }
      }
      if (!mounted) return;
      setState(() {
        _captureStatus = 'Failed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _clearCaptureAndResult() {
    ref.read(lipReadingControllerProvider.notifier).clearResult();
    setState(() {
      _captureStatus = 'Ready';
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AvsrFusionResponse?> state = ref.watch(lipReadingControllerProvider);
    final LipReadingPhase phase = ref.watch(lipReadingPhaseProvider);
    final bool uploading =
        phase == LipReadingPhase.uploading ||
        phase == LipReadingPhase.processing ||
        state.isLoading ||
        _isCapturing;

    final String phaseStatus = switch (phase) {
      LipReadingPhase.idle => _captureStatus,
      LipReadingPhase.uploading => 'uploading',
      LipReadingPhase.processing => 'processing',
      LipReadingPhase.completed => 'completed',
      LipReadingPhase.failed => 'failed',
    };

    if (!_isSupportedPlatform) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('AVSR', style: TextStyle(color: _darkRed, fontWeight: FontWeight.bold)),
          backgroundColor: _grey,
          elevation: 0,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This feature is available only on Android, iOS, and Web.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _darkRed, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('AVSR Recognition', style: TextStyle(color: _darkRed, fontWeight: FontWeight.bold)),
        backgroundColor: _grey,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Camera preview card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _darkRed.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _initializing
                      ? Container(
                          color: _grey,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(_darkRed),
                            ),
                          ),
                        )
                      : (_controller == null
                          ? Container(
                              color: _grey,
                              child: const Center(
                                child: Icon(Icons.camera_alt, color: _darkRed, size: 48),
                              ),
                            )
                          : Center(
                              child: AspectRatio(
                                aspectRatio: 3/4, // Typical phone camera ratio
                                child: ClipRect(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      RepaintBoundary(
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final previewSize = _controller!.value.previewSize;
                                            if (previewSize == null) {
                                              return CameraPreview(_controller!);
                                            }
                                            return FittedBox(
                                              fit: BoxFit.cover,
                                              child: SizedBox(
                                                width: previewSize.height,
                                                height: previewSize.width,
                                                child: CameraPreview(_controller!),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      if (_isCapturing)
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: _darkRed, width: 4),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                ),
              ),
              const SizedBox(height: 24),
              
              // Status indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _grey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: uploading ? _darkRed : _grey,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (uploading)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_lightRed),
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        phaseStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: uploading ? _darkRed : _black.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Start button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: uploading ? null : _startCaptureAndSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkRed,
                    disabledBackgroundColor: _grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: uploading ? 0 : 8,
                    shadowColor: _darkRed.withOpacity(0.15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        uploading ? Icons.hourglass_empty : Icons.mic,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        uploading
                            ? (phase == LipReadingPhase.uploading
                                ? 'Uploading...'
                                : 'Processing...')
                            : 'Start Recording',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Clear button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: uploading ? null : _clearCaptureAndResult,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _darkRed,
                    side: BorderSide(color: uploading ? _grey : _darkRed, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Clear', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
              
              // Result section
              _ResultSection(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.state});

  final AsyncValue<AvsrFusionResponse?> state;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _grey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _darkRed.withOpacity(0.15), width: 2),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_darkRed),
            ),
            SizedBox(height: 16),
            Text(
              'Processing...',
              style: TextStyle(color: _darkRed, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _grey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error.toString(),
                    style: TextStyle(color: _black.withOpacity(0.8), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      data: (response) {
        if (response == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _grey,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _darkRed.withOpacity(0.15), width: 1),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.graphic_eq, size: 48, color: _darkRed.withOpacity(0.15)),
                  const SizedBox(height: 12),
                  Text(
                    'No results yet',
                    style: TextStyle(color: _black.withOpacity(0.5), fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        final topFivePredictions = response.lipTopPredictions.take(5).toList();
        final String finalResultWord = response.finalWord.trim().isNotEmpty
          ? response.finalWord.trim()
          : (response.matchedLipWord.trim().isNotEmpty
              ? response.matchedLipWord.trim()
              : (topFivePredictions.isNotEmpty ? topFivePredictions.first.word : ''));
        final double finalConfidence = response.lipConfidence > 0
          ? response.lipConfidence
          : (topFivePredictions.isNotEmpty ? topFivePredictions.first.confidence : 0);
        final String finalConfidenceText = finalConfidence <= 1
          ? '${(finalConfidence * 100).toStringAsFixed(1)}%'
          : '${finalConfidence.toStringAsFixed(1)}%';

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_grey, _cardBg],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _darkRed.withOpacity(0.15), width: 2),
            boxShadow: [
              BoxShadow(
                color: _darkRed.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _darkRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Recognition Result',
                    style: TextStyle(
                      color: _darkRed,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Final result + confidence
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _darkRed,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FINAL RESULT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      finalResultWord.isNotEmpty ? finalResultWord : '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Confidence: $finalConfidenceText',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Audio result
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUDIO RESULT',
                      style: TextStyle(
                        color: _darkRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      response.audioText.isNotEmpty ? response.audioText : 'No audio text returned',
                      style: TextStyle(
                        color: _black.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Top 5 predictions
              Text(
                'TOP 5 PREDICTIONS',
                style: TextStyle(
                  color: _darkRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              if (topFivePredictions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No top predictions returned.',
                    style: TextStyle(
                      color: _black.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ...topFivePredictions.asMap().entries.map((entry) {
                final index = entry.key;
                final pred = entry.value;
                final bool isSelected =
                    pred.word.trim().toLowerCase() == finalResultWord.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _grey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _darkRed : _grey,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected ? _darkRed : _grey,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : _darkRed,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pred.word,
                            style: TextStyle(
                              color: _darkRed,
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _darkRed.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pred.confidence.toStringAsFixed(3),
                            style: const TextStyle(
                              color: _darkRed,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _darkRed.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
