import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  late String myUserId;
  bool otherUserTyping = false;
  bool socketConnected = false; // ✅ مهم

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      myUserId = extractUserIdFromJwt(widget.token);

      // 1️⃣ تحميل الرسائل القديمة
      final repo = ref.read(chatRepositoryProvider);
      final oldMessages = await repo.getMessages(widget.chatId);

      setState(() {
        messages.addAll(oldMessages.reversed);
      });

      // 2️⃣ إرسال SEEN
      final unreadIds = oldMessages
          .where((m) => m.senderId != myUserId && m.deliveryStatus != 'READ')
          .map((m) => m.id)
          .toList();

      // 3️⃣ الاتصال بالـ WebSocket
      socket.connect(
        baseUrl: 'http://10.0.2.2:8080',
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

  // ✅ استقبال الأحداث
  void handleEvent(Map<String, dynamic> event) {
    switch (event['eventType']) {
      case 'MESSAGE':
        final incoming = MessageModel.fromJson(event['message']);

        setState(() {
          // إزالة النسخة المؤقتة
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

  @override
  void dispose() {
    socket.disconnect();
    controller.dispose();
    super.dispose();
  }

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
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                return MessageBubble(
                  text: m.text ?? '',
                  isMe: m.senderId == myUserId,
                  deliveryStatus: m.deliveryStatus,
                );
              },
            ),
          ),
          buildInput(),
        ],
      ),
    );
  }

  // ✅ إدخال الرسائل
  Widget buildInput() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
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

                setState(() {
                  messages.add(tempMessage);
                });

                final repo = ref.read(chatRepositoryProvider);

                await repo.sendMessage(
                  chatId: widget.chatId,
                  text: text,
                );

                socket.sendMessage(widget.chatId, text);

                controller.clear();
                socket.sendTyping(widget.chatId, false);
              }),
        ],
      ),
    );
  }
}
