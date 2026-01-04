import '../../../core/network/dio_client.dart';
import '../domain/chat_model.dart';
import '../domain/message_model.dart';

class ChatApi {
  final DioClient dio;
  ChatApi(this.dio);

  Future<List<ChatModel>> getChats() async {
    final res = await dio.get('/v1/chats');
    final content = res.data['content'] as List;
    return content.map((e) => ChatModel.fromJson(e)).toList();
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    final res = await dio.get('/v1/chats/$chatId/messages');
    final content = res.data['content'] as List;
    return content.map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    await dio.post(
      '/v1/chats/$chatId/messages',
      data: {
        "type": "TEXT",
        "textContent": text,
        "mediaUrl": null,
      },
    );
  }
}
