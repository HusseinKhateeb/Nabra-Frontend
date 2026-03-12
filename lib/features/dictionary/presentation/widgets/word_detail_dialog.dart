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

  @override
  void initState() {
    super.initState();
    if (widget.word.videoUrl != null && widget.word.videoUrl!.isNotEmpty) {
      final baseUrl = AppConfig.serverBaseUrl;
      final fullVideoUrl = '$baseUrl${widget.word.videoUrl}';
      // Debug print to verify the video URL
      // ignore: avoid_print
      print('WordDetailDialog video URL: ' + fullVideoUrl);
      _controller = VideoPlayerController.networkUrl(Uri.parse(fullVideoUrl))
        ..initialize().then((_) {
          setState(() {});
        }).catchError((e) {
          // ignore: avoid_print
          print('Video initialization error: ' + e.toString());
        });
      _controller?.addListener(() {
        final isEnded = _controller!.value.position >= _controller!.value.duration && !_controller!.value.isPlaying;
        final isPlaying = _controller!.value.isPlaying;
        if (isEnded) {
          if (!_showPlayButton) {
            setState(() {
              _showPlayButton = true;
            });
          }
        } else if (isPlaying && _showPlayButton) {
          setState(() {
            _showPlayButton = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(() {});
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
