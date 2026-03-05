import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import 'user_api.dart';
import 'user_repository.dart';
import '../domain/user_model.dart';

final userApiProvider = Provider<UserApi>((ref) {
  final dio = ref.read(dioClientProvider);
  return UserApi(dio);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(userApiProvider));
});

final usersProvider = FutureProvider<List<UserModel>>((ref) {
  return ref.read(userRepositoryProvider).getUsers();
});
