import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:nabra_frontend/core/config/app_config.dart';

import './../data/chat_socket_service.dart';
import './../data/chat_providers.dart';
import './../domain/message_model.dart';
import 'widgets/message_bubble.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final String chatId;
  final String token;
  final String otherUserName;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.token,
    required this.otherUserName,
  });

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final socket = ChatSocketService();
  final controller = TextEditingController();
  final List<MessageModel> messages = [];

  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _voicePath;
  DateTime? _recordingStartedAt;
  Timer? _recordingTicker;
  int _recordingSeconds = 0;

  late String myUserId;
  bool otherUserTyping = false;
  bool socketConnected = false;
  final Set<String> _locallyDeletedMessageIds = <String>{};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      myUserId = extractUserIdFromJwt(widget.token);

      // 1️⃣ تحميل الرسائل
      final repo = ref.read(chatRepositoryProvider);
      final oldMessages = await repo.getMessages(widget.chatId);

      setState(() {
        messages.addAll(oldMessages.reversed);
      });

      // 2️⃣ SEEN
      final unreadIds = oldMessages
          .where((m) => m.senderId != myUserId && m.deliveryStatus != 'READ')
          .map((m) => m.id)
          .toList();

      // 3️⃣ WebSocket
      socket.connect(
        baseUrl: AppConfig.socketBaseUrl,
        token: widget.token,
        chatId: widget.chatId,
        onEvent: handleEvent,
      );

      socketConnected = true;

      if (unreadIds.isNotEmpty) {
        socket.sendSeen(widget.chatId, unreadIds);
      }
    });
  }

  String extractUserIdFromJwt(String token) {
    final parts = token.split('.');
    final payload =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final map = jsonDecode(payload) as Map<String, dynamic>;
    return map['sub'];
  }

  // ================= WebSocket Events =================
  void handleEvent(Map<String, dynamic> event) {
    switch (event['eventType']) {
      case 'MESSAGE':
        final incoming = MessageModel.fromJson(event['message']);
        setState(() {
          messages.removeWhere(
            (m) =>
                m.senderId == incoming.senderId &&
                m.text == incoming.text &&
                m.deliveryStatus == 'SENT',
          );
          messages.add(incoming);
        });
        break;

      case 'TYPING':
        if (event['fromUserId'] != myUserId) {
          setState(() {
            otherUserTyping = event['typing'] == true;
          });
        }
        break;

      case 'SEEN':
        final seenIds = List<String>.from(event['messageIds']);
        setState(() {
          for (var i = 0; i < messages.length; i++) {
            if (seenIds.contains(messages[i].id)) {
              messages[i] = messages[i].copyWith(deliveryStatus: 'READ');
            }
          }
        });
        break;
    }
  }

  // ================= Voice Recording =================
  Future<void> _onVoiceMessageLongPress(MessageModel message) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: ListTile(
            leading: const Icon(Icons.translate),
            title: const Text('تحويل الصوت إلى نص'),
            onTap: () => Navigator.of(context).pop('transcribe'),
          ),
        );
      },
    );

    if (action == 'transcribe') {
      await _showVoiceTranscript(message);
    }
  }

  Future<void> _showMessageActions({
    required MessageModel message,
    required Offset tapPosition,
  }) async {
    final bool isDeleted = _locallyDeletedMessageIds.contains(message.id);

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(tapPosition.dx, tapPosition.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        if (!isDeleted && message.type == 'VOICE')
          const PopupMenuItem<String>(
            value: 'transcribe',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.translate),
              title: Text('تحويل الصوت إلى نص'),
            ),
          ),
        if (!isDeleted)
          const PopupMenuItem<String>(
            value: 'softDelete',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('حذف الرسالة'),
            ),
          ),
        if (isDeleted)
          const PopupMenuItem<String>(
            value: 'hardRemove',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.remove_circle_outline, color: Colors.red),
              title: Text('إزالة نهائياً من المحادثة'),
            ),
          ),
      ],
    );

    if (!mounted || selected == null) return;

    switch (selected) {
      case 'transcribe':
        await _showVoiceTranscript(message);
        break;
      case 'softDelete':
        setState(() {
          _locallyDeletedMessageIds.add(message.id);
        });
        break;
      case 'hardRemove':
        setState(() {
          messages.removeWhere((m) => m.id == message.id);
          _locallyDeletedMessageIds.remove(message.id);
        });
        break;
    }
  }

  Future<void> _showVoiceTranscript(MessageModel message) async {
    String transcript = (message.voiceTranscript ?? '').trim();
    if (transcript.isEmpty) {
      try {
        final repo = ref.read(chatRepositoryProvider);
        transcript = (await repo.inferVoiceMessage(
          voiceMessageId: message.id,
          chatId: widget.chatId,
          accessToken: widget.token,
        )).trim();
        // Update the message in the local list
        final int localIdx = messages.indexWhere((m) => m.id == message.id);
        if (localIdx != -1 && mounted) {
          setState(() {
            messages[localIdx] = messages[localIdx].copyWith(voiceTranscript: transcript);
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحويل الصوت إلى نص: $e')),
        );
        return;
      }
    }

    if (!mounted) return;

    if (transcript.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد نص محول حالياً. تأكد من إعداد خدمة STT في الخادم.'),
        ),
      );
      return;
    }
    // No dialog needed, transcript will now show below the message bubble
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      debugPrint('❌ No mic permission');
      return;
    }

    final dir = await getTemporaryDirectory();
      _voicePath =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      // Use WAV encoder for recording
      final encoder = AudioEncoder.wav;
    await _recorder.start(
      RecordConfig(
        encoder: encoder,
        bitRate: 128000,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _voicePath!,
    );

    _recordingTicker?.cancel();
    setState(() {
      _isRecording = true;
      _recordingStartedAt = DateTime.now();
      _recordingSeconds = 0;
    });
    _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _recordingStartedAt == null) return;
      setState(() {
        _recordingSeconds = DateTime.now().difference(_recordingStartedAt!).inSeconds;
      });
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _recordingTicker?.cancel();
    setState(() {
      _isRecording = false;
      _recordingStartedAt = null;
      _recordingSeconds = 0;
    });

    if (path != null && path.isNotEmpty) {
      await _sendVoiceMessage(path);
    }
  }

  Future<void> _sendVoiceMessage(String path) async {
    final repo = ref.read(chatRepositoryProvider);
    try {
      // 1. Upload and save the voice message, get the real message from backend
      final savedMessage = await repo.uploadVoiceMessage(
        chatId: widget.chatId,
        audioFile: File(path),
        jwtToken: widget.token,
      );
      setState(() => messages.add(savedMessage));
      // No automatic inference. User must trigger transcript manually from the message menu.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إرسال الرسالة الصوتية: $e')),
      );
    }
  }

  Future<void> _cancelRecording() async {
    final path = await _recorder.stop();
    _recordingTicker?.cancel();
    setState(() {
      _isRecording = false;
      _recordingStartedAt = null;
      _recordingSeconds = 0;
    });

    if (path != null && path.isNotEmpty) {
      try {
        final file = await File(path).exists();
        if (file) {
          await File(path).delete();
        }
      } catch (_) {
        // Best effort cleanup only.
      }
    }
  }

  String _formatRecordingTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }


  @override
  void dispose() {
    socket.disconnect();
    controller.dispose();
    _recorder.dispose();
    _recordingTicker?.cancel();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName),
            if (otherUserTyping)
              const Text(
                'يكتب الآن...',
                style: TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                final bool isDeleted = _locallyDeletedMessageIds.contains(m.id);
                return MessageBubble(
                  text: isDeleted
                      ? 'تم حذف الرسالة'
                      : (m.type == 'VOICE' ? '🎤 رسالة صوتية' : (m.text ?? '')),
                  isMe: m.senderId == myUserId,
                  deliveryStatus: m.deliveryStatus,
                  isVoice: !isDeleted && m.type == 'VOICE',
                  voiceTranscript: m.voiceTranscript,
                  onLongPressAt: (pos) => _showMessageActions(
                    message: m,
                    tapPosition: pos,
                  ),
                );
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  // ================= Input =================
  Widget _buildInput() {
    if (_isRecording) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'إلغاء التسجيل',
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: _cancelRecording,
              ),
              const Icon(Icons.mic, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'جاري التسجيل... ${_formatRecordingTime(_recordingSeconds)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.graphic_eq, color: Colors.grey),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'إرسال التسجيل',
                icon: const Icon(Icons.send, color: Colors.red),
                onPressed: _stopRecording,
              ),
            ],
          ),
        ),
      );
    }
    // Normal input (not recording)
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.grey),
            onPressed: _startRecording,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (v) {
                if (socketConnected) {
                  socket.sendTyping(widget.chatId, v.isNotEmpty);
                }
              },
              decoration: const InputDecoration(
                hintText: 'اكتب رسالة...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.red),
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty || !socketConnected) return;

              final tempMessage = MessageModel(
                id: 'local-${DateTime.now().millisecondsSinceEpoch}',
                senderId: myUserId,
                type: 'TEXT',
                text: text,
                mediaUrl: null,
                sentAt: DateTime.now(),
                deliveryStatus: 'SENT',
              );

              setState(() => messages.add(tempMessage));

              final repo = ref.read(chatRepositoryProvider);
              try {
                await repo.sendMessage(
                  chatId: widget.chatId,
                  text: text,
                );
                socket.sendMessage(widget.chatId, text);
              } catch (e) {
                // Update the message to show error
                final idx = messages.indexWhere((m) => m.id == tempMessage.id);
                if (idx != -1) {
                  setState(() {
                    messages[idx] = messages[idx].copyWith(deliveryStatus: 'FAILED');
                  });
                }
              }

              controller.clear();
              socket.sendTyping(widget.chatId, false);
            },
          ),
        ],
      ),
    );
  }
}
