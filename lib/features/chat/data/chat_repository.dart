import '../domain/chat_model.dart';
import '../domain/message_model.dart';
import 'chat_api.dart';

class ChatRepository {
  final ChatApi api;
  ChatRepository(this.api);

  // ================= Chats =================
  Future<List<ChatModel>> getChats() => api.getChats();

  // ================= Messages =================
  Future<List<MessageModel>> getMessages(String chatId) =>
      api.getMessages(chatId);

  // ================= Send TEXT =================
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) =>
      api.sendTextMessage(chatId: chatId, text: text);

  // ================= Send VOICE (✅ FIXED) =================
  Future<void> sendVoiceMessage({
    required String chatId,
    required String localPath,
  }) =>
      api.sendVoiceMessage(
        chatId: chatId,
        localPath: localPath,
      );
}
