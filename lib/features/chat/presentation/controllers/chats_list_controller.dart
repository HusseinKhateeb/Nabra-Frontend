import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/chat_repository.dart';
import '../../domain/chat_model.dart';
import '../../data/chat_providers.dart';

final chatsListControllerProvider =
    StateNotifierProvider<ChatsListController, AsyncValue<List<ChatModel>>>(
  (ref) => ChatsListController(ref.read(chatRepositoryProvider)),
);

class ChatsListController extends StateNotifier<AsyncValue<List<ChatModel>>> {
  final ChatRepository repo;

  ChatsListController(this.repo) : super(const AsyncLoading());

  Future<void> loadChats() async {
    state = const AsyncLoading();
    try {
      final chats = await repo.getChats();
      state = AsyncData(chats);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<bool> deleteChat(String chatId) async {
    final previous = state;
    final currentChats = state.valueOrNull;

    if (currentChats != null) {
      state = AsyncData(
        currentChats.where((chat) => chat.id != chatId).toList(growable: false),
      );
    }

    try {
      await repo.deleteChat(chatId: chatId);
      return true;
    } catch (_) {
      state = previous;
      await loadChats();
      return false;
    }
  }
}
