import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/chat_model.dart';
import '../domain/message_model.dart';

class ChatApi {
  /// Utility: Log file info before upload (for debugging)
  Future<void> logAudioFileInfo(String filePath) async {
    final file = File(filePath);
    final exists = await file.exists();
    if (!exists) {
      print('File does not exist: $filePath');
      return;
    }
    final length = await file.length();
    print('File path: $filePath');
    print('File size: $length bytes');
    print('File type: ${filePath.split('.').last}');
  }

  /// Sample: Standalone upload function matching checklist (for demonstration)
  Future<void> uploadAudioFileSample(String filePath, String jwtToken) async {
    final dio = Dio();
    final file = await MultipartFile.fromFile(filePath,
        filename: filePath.split('/').last);
    final formData = FormData.fromMap({
      'audioFile': file,
    });
    final response = await dio.post(
      'http://your-backend-url/api/v1/lipreading/avsr/upload-audio',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $jwtToken',
          // Do NOT set Content-Type manually; Dio sets it for FormData.
        },
      ),
    );
    print(response.data);
  }

  /// Uploads a voice message (audio file) to the chat backend and returns the message model.
  Future<MessageModel> uploadVoiceMessageFile(
      {required String chatId, required String audioFilePath}) async {
    final formData = FormData.fromMap({
      'audioFile': await MultipartFile.fromFile(
        audioFilePath,
        filename: audioFilePath.split('/').last,
      ),
    });
    try {
      final response = await dio.dio.post(
        ApiEndpoints.chatVoiceMessage(chatId),
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (response.statusCode == 200 && response.data != null) {
        return MessageModel.fromJson(response.data);
      }
      throw Exception('Failed to upload voice message');
    } on DioException catch (e) {
      final String msg =
          e.response?.data?.toString() ?? e.message ?? 'Unknown error';
      throw Exception('Upload failed: $msg');
    }
  }

  /// Upload and save a voice message, returns MessageModel
  Future<MessageModel> uploadVoiceMessage({
    required String chatId,
    required File audioFile,
    required String jwtToken,
  }) async {
    final formData = FormData.fromMap({
      'audioFile': await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.uri.pathSegments.last,
      ),
    });
    final res = await dio.dio.post(
      ApiEndpoints.chatVoiceMessage(chatId),
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      ),
    );
    if (res.statusCode == 200 && res.data != null) {
      return MessageModel.fromJson(res.data);
    }
    throw Exception('Failed to upload voice message');
  }

  // Run inference (STT) on a saved voice message, returns transcript as String
  Future<String> inferVoiceMessage(
      {required String voiceMessageId,
      required String chatId,
      String? accessToken}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    try {
      final res = await dio.dio.post(
        '${ApiEndpoints.chatVoiceInfer}?voiceMessageId=$voiceMessageId',
        data: {
          'chatId': chatId,
        },
        options: Options(headers: headers),
      );
      // Robust UTF-8 decoding for Arabic
      dynamic decodedData = res.data;
      if (res.data is List<int>) {
        decodedData = jsonDecode(utf8.decode(res.data));
      } else if (res.data is String) {
        try {
          decodedData = jsonDecode(res.data);
        } catch (_) {
          decodedData = res.data;
        }
      }
      if (res.statusCode == 200 && decodedData != null) {
        if (decodedData is Map<String, dynamic> && decodedData['result'] != null) {
          return decodedData['result'] as String;
        } else if (decodedData is Map && decodedData['result'] != null) {
          return decodedData['result'].toString();
        } else if (decodedData is String) {
          return decodedData;
        } else {
          throw Exception('Invalid response format: missing result field');
        }
      }
      throw Exception('Failed to infer voice message: ${res.statusCode}');
    } catch (e) {
      throw Exception('Error during voice inference: $e');
    }
  }

  final DioClient dio;
  ChatApi(this.dio);

  // ================= Voice to Text (Lipreading) =================
  Future<String> convertVoiceToText({
    required String filePath,
    required String jwtToken,
    required String sttEndpoint,
  }) async {
    final dio = Dio();
    final file = await MultipartFile.fromFile(filePath,
        filename: filePath.split('/').last);

    final formData = FormData.fromMap({
      'audioFile': file, // field name must match backend
    });

    final response = await dio.post(
      sttEndpoint,
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $jwtToken',
          // Do NOT set Content-Type manually for multipart/form-data!
        },
      ),
    );

    // Robust UTF-8 decoding for Arabic
    dynamic decodedData = response.data;
    if (response.data is List<int>) {
      decodedData = jsonDecode(utf8.decode(response.data));
    } else if (response.data is String) {
      try {
        decodedData = jsonDecode(response.data);
      } catch (_) {
        decodedData = response.data;
      }
    }
    if (response.statusCode == 200 && decodedData != null) {
      if (decodedData is Map && decodedData['result'] != null) {
        return decodedData['result']?.toString() ?? '';
      } else if (decodedData is String) {
        return decodedData;
      } else {
        throw Exception('STT failed: Invalid response format');
      }
    } else {
      throw Exception('STT failed: ${response.statusCode}');
    }
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
