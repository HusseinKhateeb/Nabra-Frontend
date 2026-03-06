import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? deliveryStatus; // SENT / READ
  final VoidCallback? onLongPress;
  final ValueChanged<Offset>? onLongPressAt;
  final bool isVoice;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.deliveryStatus,
    this.onLongPress,
    this.onLongPressAt,
    this.isVoice = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        onLongPressStart: (details) {
          onLongPressAt?.call(details.globalPosition);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFFDECEC) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (isVoice)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        size: 16,
                        color: isMe ? Colors.white : Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.graphic_eq, color: Colors.grey, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'رسالة صوتية',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isMe ? const Color(0xFF222222) : Colors.black87,
                      ),
                    ),
                  ],
                )
              else
                Text(text),
              if (isMe && deliveryStatus != null)
                Text(
                  deliveryStatus == 'READ' ? '✓✓' : '✓',
                  style: const TextStyle(fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
