import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class LipReadingPage extends StatefulWidget {
  const LipReadingPage({super.key});

  @override
  State<LipReadingPage> createState() => _LipReadingPageState();
}

class _LipReadingPageState extends State<LipReadingPage> {
  CameraController? _controller;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lip Reading')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _initializing
                  ? const Center(child: CircularProgressIndicator())
                  : (_controller == null
                      ? const Center(child: Text('Camera not available'))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CameraPreview(_controller!),
                        )),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO: call backend /sessions/start
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Session'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: record short clip + upload then /sessions/stop
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Session'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Next: record a short clip and upload it to backend to get prediction text.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
