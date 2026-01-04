import '../domain/chat_model.dart';
import '../domain/message_model.dart';
import 'chat_api.dart';

class ChatRepository {
  final ChatApi api;
  ChatRepository(this.api);

  Future<List<ChatModel>> getChats() => api.getChats();

  Future<List<MessageModel>> getMessages(String chatId) =>
      api.getMessages(chatId);

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) {
    return api.sendMessage(chatId: chatId, text: text);
  }
}
