import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/chat_model.dart';
import '../domain/message_model.dart';

class ChatApi {
  final DioClient dio;
  ChatApi(this.dio);

  // ================= Chats =================
  Future<List<ChatModel>> getChats() async {
    final res = await dio.get('/v1/chats');
    final content = res.data['content'] as List;
    return content.map((e) => ChatModel.fromJson(e)).toList();
  }

  // ================= Messages =================
  Future<List<MessageModel>> getMessages(String chatId) async {
    final res = await dio.get('/v1/chats/$chatId/messages');
    final content = res.data['content'] as List;
    return content.map((e) => MessageModel.fromJson(e)).toList();
  }

  // ================= Send TEXT =================
  Future<void> sendTextMessage({
    required String chatId,
    required String text,
  }) async {
    await dio.post(
      '/v1/chats/$chatId/messages',
      data: {
        "type": "TEXT",
        "textContent": text,
        "mediaUrl": null,
        "voiceTranscript": null,
      },
    );
  }

  Future<ChatModel> createChat(String userId) async {
    final res = await dio.post(
      '/v1/chats',
      data: {
        "groupChat": false,
        "participantUserIds": [userId],
      },
    );
    return ChatModel.fromJson(res.data);
  }

  // ================= Send VOICE =================
  Future<void> sendVoiceMessage({
    required String chatId,
    required String localPath,
  }) async {
    await dio.post(
      '/v1/chats/$chatId/messages',
      data: {
        "type": "VOICE",
        "textContent": "🎤 رسالة صوتية",
        "mediaUrl": localPath, // مؤقت
        "voiceTranscript": null,
      },
    );
  }
}
