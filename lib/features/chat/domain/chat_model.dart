class ChatModel {
  final String id;
  final List<String> participantUserIds;
  final DateTime? lastMessageAt;

  ChatModel({
    required this.id,
    required this.participantUserIds,
    this.lastMessageAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'].toString(),
      participantUserIds: (json['participantUserIds'] as List)
          .map((e) => e.toString())
          .toList(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
    );
  }
}
