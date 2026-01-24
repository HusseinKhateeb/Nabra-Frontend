import 'package:dio/dio.dart';
import '../models/user_profile_model.dart';

class ProfileRepository {
  final Dio _dio;

  ProfileRepository({required Dio dio}) : _dio = dio;

  Future<UserProfile> getUserProfile() async {
    try {
      final response = await _dio.get('/v1/users/profile');
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch profile: ${e.message}');
    }
  }
}
