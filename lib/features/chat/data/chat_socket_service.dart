import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';

class ChatSocketService {
  StompClient? _client;

  bool get isConnected => _client != null && _client!.connected;

  void connect({
    required String baseUrl,
    required String token,
    required String chatId,
    required Function(Map<String, dynamic>) onEvent,
  }) {
    _client = StompClient(
      config: StompConfig.sockJS(
        url: '$baseUrl/ws-chat?token=$token',
        onConnect: (frame) {
          _client!.subscribe(
            destination: '/topic/chats/$chatId',
            callback: (msg) {
              if (msg.body != null) {
                onEvent(jsonDecode(msg.body!));
              }
            },
          );

          _client!.send(
            destination: '/app/chat.join',
            body: chatId,
          );
        },
      ),
    );

    _client!.activate();
  }

  void sendMessage(String chatId, String text) {
    if (!isConnected) return; // ✅ حماية
    _client!.send(
      destination: '/app/chat.send',
      body: jsonEncode({
        "chatId": chatId,
        "type": "TEXT",
        "textContent": text,
        "mediaUrl": null,
        "voiceTranscript": null,
      }),
    );
  }

  void sendTyping(String chatId, bool typing) {
    if (!isConnected) return; // ✅ حماية
    _client!.send(
      destination: '/app/chat.typing',
      body: jsonEncode({
        "chatId": chatId,
        "typing": typing,
      }),
    );
  }

  void sendSeen(String chatId, List<String> messageIds) {
    if (!isConnected) return; // ✅ حماية
    _client!.send(
      destination: '/app/chat.seen',
      body: jsonEncode({
        "chatId": chatId,
        "messageIds": messageIds,
      }),
    );
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
  }
}
