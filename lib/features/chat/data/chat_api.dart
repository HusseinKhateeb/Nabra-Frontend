
  import 'package:dio/dio.dart';
  import '../../../core/config/api_endpoints.dart';
  import '../../../core/network/dio_client.dart';
  import '../domain/chat_model.dart';
  import '../domain/message_model.dart';

class ChatApi {

    // Upload and save a voice message, returns MessageModel
    Future<MessageModel> uploadVoiceMessage({required String chatId, required String audioFilePath}) async {
      final formData = FormData.fromMap({
        'audioFile': await MultipartFile.fromFile(audioFilePath, filename: audioFilePath.split('/').last),
      });
      final res = await dio.dio.post(
        ApiEndpoints.chatVoiceMessage(chatId),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (res.statusCode == 200 && res.data != null) {
        return MessageModel.fromJson(res.data);
      }
      throw Exception('Failed to upload voice message');
    }

    // Run inference (STT) on a saved voice message, returns transcript as String
    Future<String> inferVoiceMessage({required String voiceMessageId, required String chatId, String? accessToken}) async {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      final res = await dio.dio.post(
        ApiEndpoints.chatVoiceInfer,
        data: {
          'chatId': chatId,
          'voiceMessageId': voiceMessageId,
        },
        options: Options(headers: headers),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data.toString();
      }
      throw Exception('Failed to infer voice message');
    }
  final DioClient dio;
  ChatApi(this.dio);

  // ================= Voice to Text (Lipreading) =================
  Future<String> convertVoiceToText(String audioFilePath) async {
    final formData = FormData.fromMap({
      'audioFile': await MultipartFile.fromFile(audioFilePath, filename: audioFilePath.split('/').last),
    });
    final res = await dio.dio.post(
      ApiEndpoints.lipReadingAvsrUploadAudio,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    // Assuming the response body is the transcript as plain text
    if (res.statusCode == 200 && res.data is String) {
      return res.data as String;
    }
    // If backend returns JSON, adjust accordingly
    if (res.statusCode == 200 && res.data != null) {
      return res.data.toString();
    }
    throw Exception('Failed to convert voice to text');
  }

  // ================= Chats =================
  Future<List<ChatModel>> getChats() async {
    final res = await dio.get(ApiEndpoints.chats);
    final content = res.data['content'] as List;
    return content.map((e) => ChatModel.fromJson(e)).toList();
  }

  // ================= Messages =================
  Future<List<MessageModel>> getMessages(String chatId) async {
    final res = await dio.get(ApiEndpoints.chatMessages(chatId));
    final content = res.data['content'] as List;
    return content.map((e) => MessageModel.fromJson(e)).toList();
  }

  // ================= Send TEXT =================
  Future<void> sendTextMessage({
    required String chatId,
    required String text,
  }) async {
    await dio.post(
      ApiEndpoints.chatMessages(chatId),
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
      ApiEndpoints.chats,
      data: {
        "groupChat": false,
        "participantUserIds": [userId],
      },
    );
    return ChatModel.fromJson(res.data);
  }

  Future<void> deleteChat(String chatId) async {
    await dio.delete(ApiEndpoints.chatById(chatId));
  }

  // ================= Send VOICE =================
  Future<void> sendVoiceMessage({
    required String chatId,
    required String localPath,
  }) async {
    await dio.post(
      ApiEndpoints.chatMessages(chatId),
      data: {
        "type": "VOICE",
        "textContent": null,
        "mediaUrl": localPath, // مؤقت
        "voiceTranscript": null,
      },
    );
  }
}
