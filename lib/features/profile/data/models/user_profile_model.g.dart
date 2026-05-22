// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      joinDate: json['joinDate'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      userType: json['userType'] as String,
      gender: json['gender'] as String?,
      age: (json['age'] as num?)?.toInt(),
      avatarUrl: json['avatarUrl'] as String?,
      highContrastEnabled: json['highContrastEnabled'] as bool,
      fontScale: (json['fontScale'] as num).toDouble(),
      vibrationEnabled: json['vibrationEnabled'] as bool,
      emailVerified: json['emailVerified'] as bool,
      statistics:
          Statistics.fromJson(json['statistics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'joinDate': instance.joinDate,
      'role': instance.role,
      'status': instance.status,
      'userType': instance.userType,
      'gender': instance.gender,
      'age': instance.age,
      'avatarUrl': instance.avatarUrl,
      'highContrastEnabled': instance.highContrastEnabled,
      'fontScale': instance.fontScale,
      'vibrationEnabled': instance.vibrationEnabled,
      'emailVerified': instance.emailVerified,
      'statistics': instance.statistics,
    };

_$StatisticsImpl _$$StatisticsImplFromJson(Map<String, dynamic> json) =>
    _$StatisticsImpl(
      transfers: (json['transfers'] as num).toInt(),
      hoursOfUse: (json['hoursOfUse'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
    );

Map<String, dynamic> _$$StatisticsImplToJson(_$StatisticsImpl instance) =>
    <String, dynamic>{
      'transfers': instance.transfers,
      'hoursOfUse': instance.hoursOfUse,
      'accuracy': instance.accuracy,
    };
