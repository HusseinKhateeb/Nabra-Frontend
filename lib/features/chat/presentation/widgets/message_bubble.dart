import 'package:flutter/material.dart';


class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? deliveryStatus; // SENT / READ / FAILED
  final VoidCallback? onLongPress;
  final ValueChanged<Offset>? onLongPressAt;
  final bool isVoice;
  final String? voiceTranscript;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.deliveryStatus,
    this.onLongPress,
    this.onLongPressAt,
    this.isVoice = false,
    this.voiceTranscript,
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
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFFE0E0E0) // light gray for sender
                : const Color(0xFFF5F5F5), // softer gray for receiver
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (isVoice) ...[
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
                ),
                if (voiceTranscript != null && voiceTranscript!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    voiceTranscript!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ] else
                Text(text),
              if (isMe && deliveryStatus != null)
                deliveryStatus == 'FAILED'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'فشل الإرسال',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
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
