import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
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
  Future<Uint8List?>? _thumbnailFuture;

  String? get _videoUrl => widget.word.videoUrl;

  String? get _fullVideoUrl {
    final videoUrl = _videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      return null;
    }
    return '${AppConfig.serverBaseUrl}${Uri.encodeFull(videoUrl)}';
  }

  Future<Uint8List?> _buildThumbnail(String fullVideoUrl) async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: fullVideoUrl,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 75,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Thumbnail generation failed: ' + e.toString());
      return null;
    }
  }

  void _syncThumbnail() {
    final fullVideoUrl = _fullVideoUrl;
    _thumbnailFuture = fullVideoUrl == null ? null : _buildThumbnail(fullVideoUrl);
  }

  @override
  void initState() {
    super.initState();
    _syncThumbnail();
  }

  @override
  void didUpdateWidget(covariant WordCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.word.id != widget.word.id ||
        oldWidget.word.videoUrl != widget.word.videoUrl) {
      _syncThumbnail();
    }
  }

  void _openDetailDialog() {
    showDialog(
      context: context,
      builder: (context) => WordDetailDialog(word: widget.word),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo =
        widget.word.videoUrl != null && widget.word.videoUrl!.isNotEmpty;

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
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder<Uint8List?>(
                      future: _thumbnailFuture,
                      builder: (context, snapshot) {
                        final bytes = snapshot.data;

                        if (bytes != null && bytes.isNotEmpty) {
                          return Image.memory(
                            bytes,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          );
                        }

                        return Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: Icon(
                            hasVideo ? Icons.videocam : Icons.image_not_supported,
                            size: 44,
                            color: Colors.grey.shade500,
                          ),
                        );
                      },
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.12),
                    ),
                    Center(
                      child: IconButton(
                        iconSize: 54,
                        color: Colors.white,
                        icon: const Icon(Icons.play_circle),
                        onPressed: hasVideo ? _openDetailDialog : null,
                      ),
                    ),
                  ],
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

                      // تحديث قائمة الكلمات
                      ref.invalidate(wordsProvider(widget.categoryId));
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
