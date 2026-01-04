import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import 'chat_api.dart';
import 'chat_repository.dart';

final chatApiProvider = Provider<ChatApi>((ref) {
  final dio = ref.read(dioClientProvider);
  return ChatApi(dio);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(chatApiProvider));
});
