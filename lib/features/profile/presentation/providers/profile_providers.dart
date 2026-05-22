import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repository/profile_repository.dart';

final profileRepositoryProvider = Provider((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ProfileRepository(dio: dioClient.dio);
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserProfile();
});
