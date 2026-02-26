import 'dart:io';

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

class LipReadingPage extends ConsumerStatefulWidget {
  const LipReadingPage({super.key});

  @override
  ConsumerState<LipReadingPage> createState() => _LipReadingPageState();
}

class _LipReadingPageState extends ConsumerState<LipReadingPage> {
  CameraController? _controller;
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _initializing = true;
  bool _isCapturing = false;
  String _captureStatus = 'Ready';

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    if (!_isMobilePlatform) {
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
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _audioRecorder.dispose();
    super.dispose();
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
        '${tempDir.path}/audio-${DateTime.now().millisecondsSinceEpoch}.m4a';

    ref.read(lipReadingControllerProvider.notifier).clearResult();
    setState(() {
      _isCapturing = true;
      _captureStatus = 'Recording started...';
    });

    late XFile recordedVideo;
    String? recordedAudio;
    final DateTime startedAt = DateTime.now();

    try {
      await _audioRecorder.start(const RecordConfig(), path: audioPath);
      setState(() {
        _captureStatus = 'Collecting video frames (1s) + audio (2s)...';
      });

      await camera.startVideoRecording();
      await Future<void>.delayed(const Duration(seconds: 1));
      recordedVideo = await camera.stopVideoRecording();

      if (mounted) {
        setState(() {
          _captureStatus = 'Video captured. Continuing audio to 2s...';
        });
      }

      final int elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      final int remainingAudioMs = 2000 - elapsedMs;
      if (remainingAudioMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: remainingAudioMs));
      }

      recordedAudio = await _audioRecorder.stop();

      if (mounted) {
        setState(() {
          _captureStatus = 'Uploading to backend...';
        });
      }

      if (recordedAudio == null) {
        throw Exception('Recording failed. Please try again.');
      }

      await ref.read(lipReadingControllerProvider.notifier).runAvsrFusion(
            audioFile: File(recordedAudio),
            videoFile: File(recordedVideo.path),
            topK: 5,
          );

      if (!mounted) return;
      setState(() {
        _captureStatus = 'Done';
      });
    } catch (e) {
      await _audioRecorder.stop();
      if (camera.value.isRecordingVideo) {
        await camera.stopVideoRecording();
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
    final bool uploading = state.isLoading || _isCapturing;

    if (!_isMobilePlatform) {
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
              'This feature is available on Android and iOS only.',
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
                                      CameraPreview(_controller!),
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
                        _captureStatus,
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
                        uploading ? 'Processing...' : 'Start Recording',
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
              
              // Final word
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
                      'DETECTED WORD',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      response.finalWord,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Fusion details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'Lip Word', value: response.matchedLipWord),
                    const SizedBox(height: 8),
                    _DetailRow(label: 'Audio Text', value: response.audioText),
                    const SizedBox(height: 8),
                    _DetailRow(label: 'Similarity', value: response.similarity.toStringAsFixed(3)),
                    const SizedBox(height: 8),
                    _DetailRow(label: 'Confidence', value: response.lipConfidence.toStringAsFixed(3)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _darkRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _darkRed.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: _darkRed, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              response.fusionReason,
                              style: TextStyle(
                                color: _black.withOpacity(0.9),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Top predictions
              Text(
                'TOP PREDICTIONS',
                style: TextStyle(
                  color: _darkRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ...response.lipTopPredictions.asMap().entries.map((entry) {
                final index = entry.key;
                final pred = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _grey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: index == 0 ? _darkRed : _grey,
                        width: index == 0 ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: index == 0 ? _darkRed : _grey,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: index == 0 ? Colors.white : _darkRed,
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
                              fontWeight: index == 0 ? FontWeight.bold : FontWeight.w500,
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
