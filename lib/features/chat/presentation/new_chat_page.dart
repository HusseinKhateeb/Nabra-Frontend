import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_providers.dart';
import '../domain/user_model.dart';
import '../data/chat_providers.dart';
import 'chat_room_page.dart';
import '../../../core/providers.dart';

class NewChatPage extends ConsumerWidget {
  const NewChatPage({super.key});

  String _extractUserIdFromJwt(String token) {
    final parts = token.split('.');
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final map = jsonDecode(payload) as Map<String, dynamic>;
    return map['sub'].toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      // ================= AppBar (RTL فقط) =================
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'بدء محادثة',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),

      // ================= Body (LTR طبيعي) =================
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text(
                'لا يوجد مستخدمون',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(
              height: 0,
              indent: 72,
              thickness: 0.8,
            ),
            itemBuilder: (context, i) {
              final UserModel u = users[i];

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE3F2FD),
                  child: Text(
                    u.displayName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  u.displayName,
                  textAlign: TextAlign.left, // 🔥 الاسم يسار
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  final chatRepo = ref.read(chatRepositoryProvider);
                  final token = await ref.read(tokenStorageProvider).getToken();
                  if (token == null || token.isEmpty) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الجلسة منتهية، سجل الدخول مرة أخرى.')),
                    );
                    return;
                  }

                  final String myUserId = _extractUserIdFromJwt(token);

                  final chats = await chatRepo.getChats();
                  final existingChat = chats.where((chat) {
                    final hasSelectedUser =
                        chat.participants.any((participant) => participant.id == u.id);
                    final hasCurrentUser =
                        chat.participants.any((participant) => participant.id == myUserId);
                    return hasSelectedUser && hasCurrentUser;
                  }).toList();

                  final targetChat = existingChat.isNotEmpty
                      ? existingChat.first
                      : await chatRepo.createChat(
                          participantUserId: u.id,
                        );

                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomPage(
                        chatId: targetChat.id,
                        token: token,
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
