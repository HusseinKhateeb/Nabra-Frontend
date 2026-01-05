import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_providers.dart';
import '../domain/user_model.dart';
import '../data/chat_providers.dart';
import 'chat_room_page.dart';
import '../../../core/providers.dart';

class NewChatPage extends ConsumerWidget {
  const NewChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('بدء محادثة')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (users) {
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final UserModel u = users[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(u.displayName[0]),
                ),
                title: Text(u.displayName),
                onTap: () async {
                  final chatRepo = ref.read(chatRepositoryProvider);

                  final chat = await chatRepo.createChat(
                    participantUserId: u.id,
                  );

                  final token = await ref.read(tokenStorageProvider).getToken();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomPage(
                        chatId: chat.id,
                        token: token!,
                        otherUserName: u.displayName,
                      ),
                    ),
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
