import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? deliveryStatus; // SENT / READ

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.deliveryStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
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
            Text(text),
            if (isMe && deliveryStatus != null)
              Text(
                deliveryStatus == 'READ' ? '✓✓' : '✓',
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
