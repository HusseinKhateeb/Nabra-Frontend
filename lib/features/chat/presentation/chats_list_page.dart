import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/chats_list_controller.dart';
import 'widgets/chat_tile.dart';
import '../../../core/providers.dart';
import 'chat_room_page.dart';

class ChatsListPage extends ConsumerStatefulWidget {
  const ChatsListPage({super.key});

  @override
  ConsumerState<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends ConsumerState<ChatsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatsListControllerProvider.notifier).loadChats();
    });
  }

  String extractUserIdFromJwt(String token) {
    final parts = token.split('.');
    final payload =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final map = jsonDecode(payload) as Map<String, dynamic>;
    return map['sub'].toString();
  }

  @override
  Widget build(BuildContext context) {
    final chatsState = ref.watch(chatsListControllerProvider);
    final tokenStorage = ref.watch(tokenStorageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الدردشات')),
      body: chatsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (chats) {
          return FutureBuilder<String?>(
            future: tokenStorage.getToken(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final token = snapshot.data!;
              final myUserId = extractUserIdFromJwt(token);

              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, i) {
                  final chat = chats[i];

                  final others = chat.participantUserIds
                      .where((id) => id != myUserId)
                      .toList();

                  // ✅ لا تتجاهل الشات حتى لو فيه مشارك واحد
                  final otherUserId =
                      others.isNotEmpty ? others.first : 'محادثة خاصة';

                  return ChatTile(
                    name: otherUserId,
                    lastMessage: '',
                    unread: 0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomPage(
                            chatId: chat.id,
                            token: token,
                            otherUserName: otherUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
