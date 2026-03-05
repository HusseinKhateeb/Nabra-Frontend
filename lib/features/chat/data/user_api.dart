import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/user_model.dart';

class UserApi {
  final DioClient dio;
  UserApi(this.dio);

  Future<List<UserModel>> getUsers() async {
    final res = await dio.get(ApiEndpoints.users);
    return (res.data as List).map((e) => UserModel.fromJson(e)).toList();
  }
}
