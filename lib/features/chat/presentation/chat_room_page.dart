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

    final String mediaUrl = (message.mediaUrl ?? '').trim();
    final bool localMediaPath = mediaUrl.startsWith('/') || mediaUrl.startsWith('file:');

    if (localMediaPath && transcript.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرسالة الصوتية غير مرفوعة كرابط عام، لذلك لا يمكن تحويلها تلقائياً.'),
        ),
      );
      return;
    }

    if (transcript.isEmpty) {
      final repo = ref.read(chatRepositoryProvider);
      final latestMessages = await repo.getMessages(widget.chatId);
      final int idx = latestMessages.indexWhere((m) => m.id == message.id);

      if (idx != -1) {
        final updated = latestMessages[idx];
        transcript = (updated.voiceTranscript ?? '').trim();

        final int localIdx = messages.indexWhere((m) => m.id == updated.id);
        if (localIdx != -1 && mounted) {
          setState(() {
            messages[localIdx] = updated;
          });
        }
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

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('النص المحول من الصوت', textDirection: TextDirection.rtl),
          content: SingleChildScrollView(
            child: Text(
              transcript,
              textDirection: TextDirection.rtl,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      debugPrint('❌ No mic permission');
      return;
    }

    final dir = await getTemporaryDirectory();
    _voicePath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
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

  Future<void> _sendVoiceMessage(String path) async {
    final tempMessage = MessageModel(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      senderId: myUserId,
      type: 'VOICE',
      text: '🎤 رسالة صوتية',
      mediaUrl: path, // مؤقت (local)
      sentAt: DateTime.now(),
      deliveryStatus: 'SENT',
    );

    setState(() => messages.add(tempMessage));

    final repo = ref.read(chatRepositoryProvider);

    // ✅ إرسال REST عادي (بدون multipart)
    await repo.sendVoiceMessage(
      chatId: widget.chatId,
      localPath: path,
    );

    // ✅ بث عبر WS (اختياري لكن أفضل)
    socket.sendMessage(widget.chatId, '🎤 رسالة صوتية');
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
              await repo.sendMessage(
                chatId: widget.chatId,
                text: text,
              );

              socket.sendMessage(widget.chatId, text);

              controller.clear();
              socket.sendTyping(widget.chatId, false);
            },
          ),
        ],
      ),
    );
  }
}
