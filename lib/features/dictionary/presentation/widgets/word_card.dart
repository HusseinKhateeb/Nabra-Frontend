import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'word_detail_dialog.dart';

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
  bool _showPlayButton = false;

  void _handleVideoTick() {
    final controller = _controller;
    if (controller == null || !mounted) {
      return;
    }

    final value = controller.value;
    final isEnded = value.isInitialized &&
        value.position >= value.duration &&
        !value.isPlaying;

    if (isEnded && !_showPlayButton) {
      setState(() {
        _showPlayButton = true;
      });
    }
  }

  Future<void> _initializeController() async {
    final videoUrl = widget.word.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      return;
    }

    final baseUrl = AppConfig.serverBaseUrl;
    final fullVideoUrl = '$baseUrl$videoUrl';
    // ignore: avoid_print
    print('WordCard video URL: ' + fullVideoUrl);

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(fullVideoUrl),
    );

    _controller = controller;
    await controller.initialize();

    if (!mounted || _controller != controller) {
      await controller.dispose();
      return;
    }

    controller.addListener(_handleVideoTick);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant WordCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.word.id != widget.word.id ||
        oldWidget.word.videoUrl != widget.word.videoUrl) {
      final oldController = _controller;
      _controller = null;
      _showPlayButton = false;
      oldController?.removeListener(_handleVideoTick);
      oldController?.dispose();
      _initializeController();
    }
  }

  void _openDetailDialog() {
    showDialog(
      context: context,
      builder: (context) => WordDetailDialog(word: widget.word),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleVideoTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _controller != null;

    return GestureDetector(
      onTap: _openDetailDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🎥 Video
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1,
                child: (hasVideo && _controller!.value.isInitialized)
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              clipBehavior: Clip.hardEdge,
                              child: SizedBox(
                                width: _controller!.value.size.width,
                                height: _controller!.value.size.height,
                                child: VideoPlayer(_controller!),
                              ),
                            ),
                          ),
                          if (_showPlayButton || !_controller!.value.isPlaying)
                            IconButton(
                              iconSize: 54,
                              color: Colors.white,
                              icon: Icon(Icons.play_circle),
                              onPressed: _openDetailDialog,
                            ),
                        ],
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: IconButton(
                          iconSize: 54,
                          color: hasVideo ? Colors.red : Colors.grey,
                          icon: Icon(hasVideo ? Icons.play_circle_fill : Icons.videocam),
                          onPressed: hasVideo ? _openDetailDialog : null,
                        ),
                      ),
              ),
            ),

            /// 📝 Text + Favorite
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.word.text,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final newValue = await ref
                          .read(toggleFavoriteProvider(widget.word).future);

                      if (!mounted) return;

                      setState(() {
                        widget.word.favorite = newValue;
                      });

                      // Refresh the category payload so the embedded words list stays in sync.
                      ref.invalidate(categoriesProvider);
                    },
                    child: Icon(
                      widget.word.favorite
                          ? Icons.star
                          : Icons.star_border_outlined,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            /// 🧾 Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                widget.word.description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),

            const Spacer(),

            /// 🔴 Bottom bar
            Container(
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
