import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/word_model.dart';
import '../../../../core/config/app_config.dart';

class WordDetailDialog extends StatefulWidget {
  final WordModel word;
  const WordDetailDialog({super.key, required this.word});

  @override
  State<WordDetailDialog> createState() => _WordDetailDialogState();
}

class _WordDetailDialogState extends State<WordDetailDialog> {
  VideoPlayerController? _controller;
  bool _showPlayButton = false;

  void _onVideoTick() {
    final controller = _controller;
    if (controller == null || !mounted) {
      return;
    }

    final value = controller.value;
    final isEnded = value.isInitialized &&
        value.position >= value.duration &&
        !value.isPlaying;
    final isPlaying = value.isPlaying;

    if (isEnded && !_showPlayButton) {
      setState(() {
        _showPlayButton = true;
      });
    } else if (isPlaying && _showPlayButton) {
      setState(() {
        _showPlayButton = false;
      });
    }
  }

  Future<void> _initializeVideo() async {
    final rawVideoUrl = widget.word.videoUrl;
    if (rawVideoUrl == null || rawVideoUrl.isEmpty) {
      return;
    }

    final baseUrl = AppConfig.serverBaseUrl;
    final encodedVideoUrl = Uri.encodeFull(rawVideoUrl);
    final fullVideoUrl = '$baseUrl$encodedVideoUrl';
    // ignore: avoid_print
    print('WordDetailDialog video URL: ' + fullVideoUrl);

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(fullVideoUrl),
    );
    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onVideoTick);
      await controller.play();
      if (mounted) {
        setState(() {
          _showPlayButton = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Video initialization error: ' + e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.word.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 12),
            if (_controller != null && _controller!.value.hasError)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('تعذر تحميل الفيديو', style: TextStyle(color: Colors.red)),
              )
            else if (_controller != null && _controller!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller!),
                    if (_showPlayButton || !_controller!.value.isPlaying)
                      IconButton(
                        iconSize: 54,
                        color: Colors.white,
                        icon: Icon(Icons.play_circle),
                        onPressed: () {
                          _controller!.seekTo(Duration.zero);
                          _controller!.play();
                          setState(() {
                            _showPlayButton = false;
                          });
                        },
                      ),
                  ],
                ),
              )
            else if (widget.word.videoUrl != null && widget.word.videoUrl!.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 12),
            Text(widget.word.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
