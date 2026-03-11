

  import 'dart:io';
  import '../domain/chat_model.dart';
  import '../domain/message_model.dart';
  import 'chat_api.dart';


class ChatRepository {
    // Permanently delete a message by ID
    Future<void> deleteMessage({required String chatId, required String messageId, required String jwtToken}) =>
      api.deleteMessage(chatId: chatId, messageId: messageId, jwtToken: jwtToken);

    // Upload and save a voice message, returns MessageModel
    Future<MessageModel> uploadVoiceMessage({
      required String chatId,
      required File audioFile,
      required String jwtToken,
    }) =>
      api.uploadVoiceMessage(
        chatId: chatId,
        audioFile: audioFile,
        jwtToken: jwtToken,
      );

    // Run inference (STT) on a saved voice message, returns transcript as String
    Future<String> inferVoiceMessage({
      required String voiceMessageId,
      required String chatId,
      String? audioFilePath,
      String? accessToken,
    }) =>
      api.inferVoiceMessage(
        voiceMessageId: voiceMessageId,
        chatId: chatId,
        accessToken: accessToken,
      );
  final ChatApi api;
  ChatRepository(this.api);

  // ================= Voice to Text (Lipreading) =================
  Future<String> convertVoiceToText({
    required String filePath,
    required String jwtToken,
    required String sttEndpoint,
  }) =>
      api.convertVoiceToText(
        filePath: filePath,
        jwtToken: jwtToken,
        sttEndpoint: sttEndpoint,
      );
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
  Future<ChatModel> createChat({
    required String participantUserId,
  }) =>
      api.createChat(participantUserId);

  Future<void> deleteChat({
    required String chatId,
  }) =>
      api.deleteChat(chatId);

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
