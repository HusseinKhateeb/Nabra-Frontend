class MessageModel {
  final String id;
  final String senderId;
  final String type;
  final String? text;
  final String? mediaUrl;
  final String? voiceTranscript;
  final DateTime sentAt;
  final String deliveryStatus;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.type,
    this.text,
    this.mediaUrl,
    this.voiceTranscript,
    required this.sentAt,
    required this.deliveryStatus,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'].toString(),
      senderId: json['senderId'].toString(),
      type: json['type'],
      text: json['textContent'],
      mediaUrl: json['mediaUrl'],
      voiceTranscript: json['voiceTranscript'],
      sentAt: DateTime.parse(json['sentAt']),
      deliveryStatus: json['deliveryStatus'],
    );
  }

  MessageModel copyWith({String? deliveryStatus, String? voiceTranscript}) {
    return MessageModel(
      id: id,
      senderId: senderId,
      type: type,
      text: text,
      mediaUrl: mediaUrl,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      sentAt: sentAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
    );
  }
}
