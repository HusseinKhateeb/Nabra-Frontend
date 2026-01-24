import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String username,
    required String displayName,
    required String email,
    String? phoneNumber,
    required String joinDate,
    required String role,
    required String status,
    required String userType,
    String? gender,
    int? age,
    String? avatarUrl,
    required bool highContrastEnabled,
    required double fontScale,
    required bool vibrationEnabled,
    required bool emailVerified,
    required Statistics statistics,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

@freezed
class Statistics with _$Statistics {
  const factory Statistics({
    required int transfers,
    required double hoursOfUse,
    required double accuracy,
  }) = _Statistics;

  factory Statistics.fromJson(Map<String, dynamic> json) =>
      _$StatisticsFromJson(json);
}
