class ChatParticipant {
  final String id;
  final String displayName;
  final String? avatarUrl;

  ChatParticipant({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'],
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
    );
  }
}
