import 'chat_participant.dart';

class ChatModel {
  final String id;
  final List<ChatParticipant> participants;
  final DateTime? lastMessageAt;
  final String lastMessageText;
  final int unreadCount;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessageText,
    required this.unreadCount,
    this.lastMessageAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      participants: (json['participants'] as List)
          .map((e) => ChatParticipant.fromJson(e))
          .toList(),
      lastMessageText: json['lastMessageText'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
    );
  }
}
