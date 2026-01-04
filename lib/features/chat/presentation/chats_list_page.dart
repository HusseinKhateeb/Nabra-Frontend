import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/chats_list_controller.dart';
import 'widgets/chat_tile.dart';
import '../../../core/providers.dart';
import 'chat_room_page.dart';
import '../../../core/widgets/main_bottom_nav_bar.dart';

class ChatsListPage extends ConsumerStatefulWidget {
  const ChatsListPage({super.key});

  @override
  ConsumerState<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends ConsumerState<ChatsListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
      extendBody: true, // 🔥 مهم جدًا لزر الكاميرا
      backgroundColor: const Color(0xFFF7F7F7),

      // ================= AppBar =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Text(
                'الدردشات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.red,
                size: 18,
              ),
            ],
          ),
        ),
      ),

      // ================= Body =================
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                setState(() => _searchQuery = v.trim());
              },
              decoration: InputDecoration(
                hintText: 'يمكنك البحث عن محادثاتك هنا',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📋 Chats list
          Expanded(
            child: chatsState.when(
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

                    final filteredChats = chats.where((chat) {
                      final otherUser = chat.participants.firstWhere(
                        (p) => p.id != myUserId,
                        orElse: () => chat.participants.first,
                      );
                      return otherUser.displayName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                    }).toList();

                    if (filteredChats.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد محادثات',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: filteredChats.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 0, indent: 72),
                      itemBuilder: (context, i) {
                        final chat = filteredChats[i];

                        final otherUser = chat.participants.firstWhere(
                          (p) => p.id != myUserId,
                          orElse: () => chat.participants.first,
                        );

                        return ChatTile(
                          name: otherUser.displayName,
                          avatarUrl: otherUser.avatarUrl,
                          lastMessage: chat.lastMessageText,
                          time: _formatTime(chat.lastMessageAt),
                          unread: chat.unreadCount,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomPage(
                                  chatId: chat.id,
                                  token: token,
                                  otherUserName: otherUser.displayName,
                                ),
                              ),
                            );

                            // ✅ تحديث العداد بعد الرجوع
                            ref
                                .read(chatsListControllerProvider.notifier)
                                .loadChats();
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ================= Bottom Nav =================
      bottomNavigationBar: SafeArea(
        top: false,
        child: MainBottomNavBar(
          currentIndex: 4,
          onTap: (index) {
            // اربطه بالراوتينغ لاحقًا
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
