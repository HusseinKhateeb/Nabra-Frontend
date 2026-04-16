import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/main_bottom_nav_bar.dart';
import '../domain/avsr_models.dart';
import 'lip_reading_providers.dart';

// Unified app red palette (matches login/profile/chat tone)
const Color _darkRed = Color(0xFFD32F2F);
const Color _lightRed = Color(0xFFE53935);
const Color _black = Color(0xFF222222);
const Color _grey = Color(0xFFEEEEEE);
const Color _pageBg = Color(0xFFF5F5F5);

const int _videoCaptureDurationMs = 1000;
const int _audioCaptureDurationMs = 1000;
const int _capturedFrameTarget = 25;
const int _targetBackendFrames = 25;
const int _recordingFps = 25;
const double _estimatedCaptureFps = 25.0;
const double _audioBoostGain = 1.0;
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
  String _captureStatus = 'جاهز';

  bool get _isSupportedPlatform {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  bool get _isMobilePlatform {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<InputDevice?> _selectPreferredInputDevice() async {
    try {
      final devices = await _audioRecorder.listInputDevices();
      if (devices.isEmpty) return null;

      final preferred = devices.where((device) {
        final label = device.label.toLowerCase();
        return !label.contains('bluetooth') &&
            !label.contains('airpods') &&
            !label.contains('a2dp') &&
            !label.contains('hands-free') &&
            !label.contains('handsfree') &&
            !label.contains('sco');
      }).toList();

      return preferred.isNotEmpty ? preferred.first : null;
    } catch (_) {
      return null;
    }
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
        throw Exception('تعذر تهيئة الكاميرا بالدقة المدعومة.');
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
    if (gain == 1.0) {
      return sourceFile;
    }

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

    for (int offset = _wavHeaderSize;
        offset + 1 < boostedBytes.length;
        offset += 2) {
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
        const SnackBar(content: Text('الكاميرا غير جاهزة حالياً.')),
      );
      return;
    }

    ref.read(lipReadingControllerProvider.notifier).clearResult();
    setState(() {
      _isCapturing = true;
      _captureStatus = 'بدأ التسجيل...';
    });

    late XFile recordedVideo;
    String? recordedAudio;
    final DateTime startedAt = DateTime.now();

    try {
      if (kIsWeb) {
        setState(() {
          _isCapturing = false;
          _captureStatus = 'الميزة تحتاج صوتاً وفيديو معاً.';
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'هذه الميزة تتطلب صوتاً وفيديو وهي غير مدعومة حالياً على الويب.'),
          ),
        );
        return;
      } else {
        // Mobile: Record audio and video
        final bool hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يجب السماح باستخدام الميكروفون.')),
          );
          return;
        }

        final Directory tempDir = await getTemporaryDirectory();
        final String audioPath =
            '${tempDir.path}/audio-${DateTime.now().millisecondsSinceEpoch}.wav';
        final InputDevice? preferredInput = await _selectPreferredInputDevice();

        // Backend-friendly capture: WAV mono 16kHz PCM with minimal DSP.
        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
            autoGain: false,
            echoCancel: false,
            noiseSuppress: false,
            device: preferredInput,
            androidConfig: const AndroidRecordConfig(
              audioSource: AndroidAudioSource.mic,
              manageBluetooth: false,
              audioManagerMode: AudioManagerMode.modeNormal,
              speakerphone: false,
            ),
            iosConfig: const IosRecordConfig(
              categoryOptions: [
                IosAudioCategoryOption.defaultToSpeaker,
              ],
            ),
          ),
          path: audioPath,
        );
        setState(() {
          _captureStatus = 'جارٍ تسجيل الفيديو والصوت...';
        });

        try {
          await camera.prepareForVideoRecording();
        } catch (_) {
          // best-effort pre-prepare right before recording
        }
        await camera.startVideoRecording();
        final DateTime videoStartedAt = DateTime.now();
        await Future<void>.delayed(
            const Duration(milliseconds: _videoCaptureDurationMs));
        recordedVideo = await camera.stopVideoRecording();
        final int actualVideoDurationMs =
            DateTime.now().difference(videoStartedAt).inMilliseconds;
        final int estimatedFramesSent =
            ((actualVideoDurationMs / 1000) * _estimatedCaptureFps).round();

        if (mounted) {
          setState(() {
            _captureStatus = 'تم تسجيل الفيديو، جارٍ إكمال الصوت...';
          });
        }

        final int elapsedMs =
            DateTime.now().difference(startedAt).inMilliseconds;
        final int remainingAudioMs = _audioCaptureDurationMs - elapsedMs;
        if (remainingAudioMs > 0) {
          await Future<void>.delayed(Duration(milliseconds: remainingAudioMs));
        }

        recordedAudio = await _audioRecorder.stop();

        if (mounted) {
          setState(() {
            _captureStatus = 'جارٍ تحسين جودة الصوت...';
          });
        }

        // Check audio file
        if (recordedAudio == null || recordedAudio.isEmpty) {
          setState(() {
            _isCapturing = false;
            _captureStatus = 'فشل تسجيل الصوت.';
          });
          return;
        }
        // Check video file
        if (recordedVideo.path.isEmpty ||
            !(await File(recordedVideo.path).exists())) {
          setState(() {
            _isCapturing = false;
            _captureStatus = 'فشل تسجيل الفيديو.';
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
            _captureStatus = 'جارٍ إرسال البيانات...';
          });
        }
        // Keep mp4 name for backend compatibility; try fast rename first.
        final mp4VideoPath =
            '${tempDir.path}/video-${DateTime.now().millisecondsSinceEpoch}.mp4';
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
        debugPrint(
            'Audio file: path=${boostedAudioFile.path}, exists=$audioExists, size=${audioSize} bytes, ext=$audioExt, gain=$_audioBoostGain');
        debugPrint(
            'Video file: path=${videoFile.path}, exists=$videoExists, size=${videoSize} bytes, ext=$videoExt');
        debugPrint(
            'Capture profile -> video=${actualVideoDurationMs}ms, audioTarget=${_audioCaptureDurationMs}ms, capturedFramesTarget=$_capturedFrameTarget, backendFramesTarget=$_targetBackendFrames');
        debugPrint(
            'Estimated raw captured frames: ~$estimatedFramesSent (estFPS=$_estimatedCaptureFps)');
        if ((estimatedFramesSent - _capturedFrameTarget).abs() >
            _frameTolerance) {
          debugPrint(
              '[WARNING] Estimated raw frames ($estimatedFramesSent) differ from target ($_capturedFrameTarget).');
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
        _captureStatus = 'تم بنجاح';
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
        _captureStatus = 'فشلت العملية';
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
      _captureStatus = 'جاهز';
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AvsrFusionResponse?> state =
        ref.watch(lipReadingControllerProvider);
    final bool uploading = state.isLoading || _isCapturing;

    if (!_isSupportedPlatform) {
      return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: _pageBg,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: const Text(
                'قراءة الشفاه',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
            bottomNavigationBar: Directionality(
              textDirection: TextDirection.ltr,
              child: MainBottomNavBar(
                currentIndex: 2,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      context.go(AppRoutes.dictionary);
                      break;
                    case 1:
                      context.go(AppRoutes.sessions);
                      break;
                    case 2:
                      break;
                    case 3:
                      context.go(AppRoutes.profile);
                      break;
                    case 4:
                      context.go(AppRoutes.chats);
                      break;
                  }
                },
              ),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'هذه الميزة تعمل فقط على أندرويد و iOS والويب.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _darkRed, fontSize: 16),
                ),
              ),
            ),
          ));
    }

    return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _pageBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: const Text(
              'قراءة الشفاه',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Camera preview card
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _initializing
                          ? Container(
                              color: _grey,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(_darkRed),
                                ),
                              ),
                            )
                          : (_controller == null
                              ? Container(
                                  color: _grey,
                                  child: const Center(
                                    child: Icon(Icons.camera_alt,
                                        color: _darkRed, size: 48),
                                  ),
                                )
                              : Center(
                                  child: AspectRatio(
                                    aspectRatio: 3 / 4,
                                    child: ClipRect(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          RepaintBoundary(
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                final previewSize = _controller!
                                                    .value.previewSize;
                                                if (previewSize == null) {
                                                  return CameraPreview(
                                                      _controller!);
                                                }
                                                return FittedBox(
                                                  fit: BoxFit.cover,
                                                  child: SizedBox(
                                                    width: previewSize.height,
                                                    height: previewSize.width,
                                                    child: CameraPreview(
                                                        _controller!),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          if (_isCapturing)
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: _darkRed, width: 3),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: uploading ? _darkRed : const Color(0xFFE0E0E0),
                        width: 1,
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(_lightRed),
                              ),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            _captureStatus,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: uploading
                                  ? _darkRed
                                  : _black.withOpacity(0.7),
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
                        disabledBackgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
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
                            uploading ? 'جارٍ المعالجة...' : 'ابدأ التسجيل',
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
                        side: BorderSide(
                            color: uploading ? _grey : _darkRed, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('مسح',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Result section
                  _ResultSection(state: state),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Directionality(
            textDirection: TextDirection.ltr,
            child: MainBottomNavBar(
              currentIndex: 2,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go(AppRoutes.dictionary);
                    break;
                  case 1:
                    context.go(AppRoutes.sessions);
                    break;
                  case 2:
                    break;
                  case 3:
                    context.go(AppRoutes.profile);
                    break;
                  case 4:
                    context.go(AppRoutes.chats);
                    break;
                }
              },
            ),
          ),
        ));
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_darkRed),
            ),
            SizedBox(height: 16),
            Text(
              'جارٍ المعالجة...',
              style: TextStyle(
                  color: _darkRed, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent),
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
                    'خطأ',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error.toString(),
                    style:
                        TextStyle(color: _black.withOpacity(0.8), fontSize: 14),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.graphic_eq,
                      size: 48, color: _darkRed.withOpacity(0.15)),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد نتائج بعد',
                    style:
                        TextStyle(color: _black.withOpacity(0.5), fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        final String finalResultWord = response.finalWord.trim().isNotEmpty
            ? response.finalWord.trim()
            : (response.matchedLipWord.trim().isNotEmpty
                ? response.matchedLipWord.trim()
                : (response.lipTopPredictions.isNotEmpty
                    ? response.lipTopPredictions.first.word
                    : ''));
        final double finalConfidence = response.lipConfidence > 0
            ? response.lipConfidence
            : (response.lipTopPredictions.isNotEmpty
                ? response.lipTopPredictions.first.confidence
                : 0);
        final String finalConfidenceText = finalConfidence <= 1
            ? '${(finalConfidence * 100).toStringAsFixed(1)}%'
            : '${finalConfidence.toStringAsFixed(1)}%';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'نتيجة التعرف',
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'النتيجة النهائية',
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
                        const Icon(Icons.verified,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'نسبة الثقة: $finalConfidenceText',
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
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نتيجة الصوت',
                      style: TextStyle(
                        color: _darkRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      response.audioText.isNotEmpty
                          ? response.audioText
                          : 'لم يتم إرجاع نص صوتي',
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

              // ...removed top predictions section, only winner word is shown...
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
