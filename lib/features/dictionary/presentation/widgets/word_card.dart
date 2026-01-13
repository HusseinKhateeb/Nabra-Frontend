import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/word_model.dart';
import '../../providers/dictionary_providers.dart';
import '../../../../core/config/app_config.dart';

class WordCard extends ConsumerStatefulWidget {
  final WordModel word;
  final String categoryId;

  const WordCard({
    super.key,
    required this.word,
    required this.categoryId,
  });

  @override
  ConsumerState<WordCard> createState() => _WordCardState();
}

class _WordCardState extends ConsumerState<WordCard> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    if (widget.word.videoUrl != null && widget.word.videoUrl!.isNotEmpty) {
      final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');

      _controller = VideoPlayerController.networkUrl(
        Uri.parse('$baseUrl${widget.word.videoUrl}'),
      )..initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          /// 🎥 Video
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: _controller != null && _controller!.value.isInitialized
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller!),
                        IconButton(
                          iconSize: 48,
                          color: Colors.white,
                          icon: Icon(
                            _controller!.value.isPlaying
                                ? Icons.pause_circle
                                : Icons.play_circle,
                          ),
                          onPressed: () {
                            setState(() {
                              _controller!.value.isPlaying
                                  ? _controller!.pause()
                                  : _controller!.play();
                            });
                          },
                        ),
                      ],
                    )
                  : const Center(
                      child: Icon(
                        Icons.videocam,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),

          /// 📝 Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.word.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        widget.word.favorite ? Icons.star : Icons.star_border,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        await ref.read(
                          toggleFavoriteProvider(widget.word).future,
                        );

                        if (!mounted) return;

                        setState(() {
                          widget.word.favorite = !widget.word.favorite;
                        });

                        ref.invalidate(
                          wordsProvider(widget.categoryId),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.word.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
