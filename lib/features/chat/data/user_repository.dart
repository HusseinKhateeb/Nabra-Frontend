import '../domain/user_model.dart';
import 'user_api.dart';

class UserRepository {
  final UserApi api;
  UserRepository(this.api);

  Future<List<UserModel>> getUsers() => api.getUsers();
}
