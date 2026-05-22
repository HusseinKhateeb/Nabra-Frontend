// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  String get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get phoneNumber => throw _privateConstructorUsedError;
  String get joinDate => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get userType => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  int? get age => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  bool get highContrastEnabled => throw _privateConstructorUsedError;
  double get fontScale => throw _privateConstructorUsedError;
  bool get vibrationEnabled => throw _privateConstructorUsedError;
  bool get emailVerified => throw _privateConstructorUsedError;
  Statistics get statistics => throw _privateConstructorUsedError;

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {String id,
      String username,
      String displayName,
      String email,
      String? phoneNumber,
      String joinDate,
      String role,
      String status,
      String userType,
      String? gender,
      int? age,
      String? avatarUrl,
      bool highContrastEnabled,
      double fontScale,
      bool vibrationEnabled,
      bool emailVerified,
      Statistics statistics});

  $StatisticsCopyWith<$Res> get statistics;
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? displayName = null,
    Object? email = null,
    Object? phoneNumber = freezed,
    Object? joinDate = null,
    Object? role = null,
    Object? status = null,
    Object? userType = null,
    Object? gender = freezed,
    Object? age = freezed,
    Object? avatarUrl = freezed,
    Object? highContrastEnabled = null,
    Object? fontScale = null,
    Object? vibrationEnabled = null,
    Object? emailVerified = null,
    Object? statistics = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      joinDate: null == joinDate
          ? _value.joinDate
          : joinDate // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      userType: null == userType
          ? _value.userType
          : userType // ignore: cast_nullable_to_non_nullable
              as String,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      age: freezed == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      highContrastEnabled: null == highContrastEnabled
          ? _value.highContrastEnabled
          : highContrastEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      fontScale: null == fontScale
          ? _value.fontScale
          : fontScale // ignore: cast_nullable_to_non_nullable
              as double,
      vibrationEnabled: null == vibrationEnabled
          ? _value.vibrationEnabled
          : vibrationEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      emailVerified: null == emailVerified
          ? _value.emailVerified
          : emailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      statistics: null == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as Statistics,
    ) as $Val);
  }

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StatisticsCopyWith<$Res> get statistics {
    return $StatisticsCopyWith<$Res>(_value.statistics, (value) {
      return _then(_value.copyWith(statistics: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String username,
      String displayName,
      String email,
      String? phoneNumber,
      String joinDate,
      String role,
      String status,
      String userType,
      String? gender,
      int? age,
      String? avatarUrl,
      bool highContrastEnabled,
      double fontScale,
      bool vibrationEnabled,
      bool emailVerified,
      Statistics statistics});

  @override
  $StatisticsCopyWith<$Res> get statistics;
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? displayName = null,
    Object? email = null,
    Object? phoneNumber = freezed,
    Object? joinDate = null,
    Object? role = null,
    Object? status = null,
    Object? userType = null,
    Object? gender = freezed,
    Object? age = freezed,
    Object? avatarUrl = freezed,
    Object? highContrastEnabled = null,
    Object? fontScale = null,
    Object? vibrationEnabled = null,
    Object? emailVerified = null,
    Object? statistics = null,
  }) {
    return _then(_$UserProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phoneNumber: freezed == phoneNumber
          ? _value.phoneNumber
          : phoneNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      joinDate: null == joinDate
          ? _value.joinDate
          : joinDate // ignore: cast_nullable_to_non_nullable
              as String,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      userType: null == userType
          ? _value.userType
          : userType // ignore: cast_nullable_to_non_nullable
              as String,
      gender: freezed == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as String?,
      age: freezed == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int?,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      highContrastEnabled: null == highContrastEnabled
          ? _value.highContrastEnabled
          : highContrastEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      fontScale: null == fontScale
          ? _value.fontScale
          : fontScale // ignore: cast_nullable_to_non_nullable
              as double,
      vibrationEnabled: null == vibrationEnabled
          ? _value.vibrationEnabled
          : vibrationEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      emailVerified: null == emailVerified
          ? _value.emailVerified
          : emailVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      statistics: null == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as Statistics,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl(
      {required this.id,
      required this.username,
      required this.displayName,
      required this.email,
      this.phoneNumber,
      required this.joinDate,
      required this.role,
      required this.status,
      required this.userType,
      this.gender,
      this.age,
      this.avatarUrl,
      required this.highContrastEnabled,
      required this.fontScale,
      required this.vibrationEnabled,
      required this.emailVerified,
      required this.statistics});

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String username;
  @override
  final String displayName;
  @override
  final String email;
  @override
  final String? phoneNumber;
  @override
  final String joinDate;
  @override
  final String role;
  @override
  final String status;
  @override
  final String userType;
  @override
  final String? gender;
  @override
  final int? age;
  @override
  final String? avatarUrl;
  @override
  final bool highContrastEnabled;
  @override
  final double fontScale;
  @override
  final bool vibrationEnabled;
  @override
  final bool emailVerified;
  @override
  final Statistics statistics;

  @override
  String toString() {
    return 'UserProfile(id: $id, username: $username, displayName: $displayName, email: $email, phoneNumber: $phoneNumber, joinDate: $joinDate, role: $role, status: $status, userType: $userType, gender: $gender, age: $age, avatarUrl: $avatarUrl, highContrastEnabled: $highContrastEnabled, fontScale: $fontScale, vibrationEnabled: $vibrationEnabled, emailVerified: $emailVerified, statistics: $statistics)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.joinDate, joinDate) ||
                other.joinDate == joinDate) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.userType, userType) ||
                other.userType == userType) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.highContrastEnabled, highContrastEnabled) ||
                other.highContrastEnabled == highContrastEnabled) &&
            (identical(other.fontScale, fontScale) ||
                other.fontScale == fontScale) &&
            (identical(other.vibrationEnabled, vibrationEnabled) ||
                other.vibrationEnabled == vibrationEnabled) &&
            (identical(other.emailVerified, emailVerified) ||
                other.emailVerified == emailVerified) &&
            (identical(other.statistics, statistics) ||
                other.statistics == statistics));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      username,
      displayName,
      email,
      phoneNumber,
      joinDate,
      role,
      status,
      userType,
      gender,
      age,
      avatarUrl,
      highContrastEnabled,
      fontScale,
      vibrationEnabled,
      emailVerified,
      statistics);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(
      this,
    );
  }
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile(
      {required final String id,
      required final String username,
      required final String displayName,
      required final String email,
      final String? phoneNumber,
      required final String joinDate,
      required final String role,
      required final String status,
      required final String userType,
      final String? gender,
      final int? age,
      final String? avatarUrl,
      required final bool highContrastEnabled,
      required final double fontScale,
      required final bool vibrationEnabled,
      required final bool emailVerified,
      required final Statistics statistics}) = _$UserProfileImpl;

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get username;
  @override
  String get displayName;
  @override
  String get email;
  @override
  String? get phoneNumber;
  @override
  String get joinDate;
  @override
  String get role;
  @override
  String get status;
  @override
  String get userType;
  @override
  String? get gender;
  @override
  int? get age;
  @override
  String? get avatarUrl;
  @override
  bool get highContrastEnabled;
  @override
  double get fontScale;
  @override
  bool get vibrationEnabled;
  @override
  bool get emailVerified;
  @override
  Statistics get statistics;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Statistics _$StatisticsFromJson(Map<String, dynamic> json) {
  return _Statistics.fromJson(json);
}

/// @nodoc
mixin _$Statistics {
  int get transfers => throw _privateConstructorUsedError;
  double get hoursOfUse => throw _privateConstructorUsedError;
  double get accuracy => throw _privateConstructorUsedError;

  /// Serializes this Statistics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Statistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StatisticsCopyWith<Statistics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StatisticsCopyWith<$Res> {
  factory $StatisticsCopyWith(
          Statistics value, $Res Function(Statistics) then) =
      _$StatisticsCopyWithImpl<$Res, Statistics>;
  @useResult
  $Res call({int transfers, double hoursOfUse, double accuracy});
}

/// @nodoc
class _$StatisticsCopyWithImpl<$Res, $Val extends Statistics>
    implements $StatisticsCopyWith<$Res> {
  _$StatisticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Statistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transfers = null,
    Object? hoursOfUse = null,
    Object? accuracy = null,
  }) {
    return _then(_value.copyWith(
      transfers: null == transfers
          ? _value.transfers
          : transfers // ignore: cast_nullable_to_non_nullable
              as int,
      hoursOfUse: null == hoursOfUse
          ? _value.hoursOfUse
          : hoursOfUse // ignore: cast_nullable_to_non_nullable
              as double,
      accuracy: null == accuracy
          ? _value.accuracy
          : accuracy // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StatisticsImplCopyWith<$Res>
    implements $StatisticsCopyWith<$Res> {
  factory _$$StatisticsImplCopyWith(
          _$StatisticsImpl value, $Res Function(_$StatisticsImpl) then) =
      __$$StatisticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int transfers, double hoursOfUse, double accuracy});
}

/// @nodoc
class __$$StatisticsImplCopyWithImpl<$Res>
    extends _$StatisticsCopyWithImpl<$Res, _$StatisticsImpl>
    implements _$$StatisticsImplCopyWith<$Res> {
  __$$StatisticsImplCopyWithImpl(
      _$StatisticsImpl _value, $Res Function(_$StatisticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of Statistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transfers = null,
    Object? hoursOfUse = null,
    Object? accuracy = null,
  }) {
    return _then(_$StatisticsImpl(
      transfers: null == transfers
          ? _value.transfers
          : transfers // ignore: cast_nullable_to_non_nullable
              as int,
      hoursOfUse: null == hoursOfUse
          ? _value.hoursOfUse
          : hoursOfUse // ignore: cast_nullable_to_non_nullable
              as double,
      accuracy: null == accuracy
          ? _value.accuracy
          : accuracy // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StatisticsImpl implements _Statistics {
  const _$StatisticsImpl(
      {required this.transfers,
      required this.hoursOfUse,
      required this.accuracy});

  factory _$StatisticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$StatisticsImplFromJson(json);

  @override
  final int transfers;
  @override
  final double hoursOfUse;
  @override
  final double accuracy;

  @override
  String toString() {
    return 'Statistics(transfers: $transfers, hoursOfUse: $hoursOfUse, accuracy: $accuracy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StatisticsImpl &&
            (identical(other.transfers, transfers) ||
                other.transfers == transfers) &&
            (identical(other.hoursOfUse, hoursOfUse) ||
                other.hoursOfUse == hoursOfUse) &&
            (identical(other.accuracy, accuracy) ||
                other.accuracy == accuracy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, transfers, hoursOfUse, accuracy);

  /// Create a copy of Statistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StatisticsImplCopyWith<_$StatisticsImpl> get copyWith =>
      __$$StatisticsImplCopyWithImpl<_$StatisticsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StatisticsImplToJson(
      this,
    );
  }
}

abstract class _Statistics implements Statistics {
  const factory _Statistics(
      {required final int transfers,
      required final double hoursOfUse,
      required final double accuracy}) = _$StatisticsImpl;

  factory _Statistics.fromJson(Map<String, dynamic> json) =
      _$StatisticsImpl.fromJson;

  @override
  int get transfers;
  @override
  double get hoursOfUse;
  @override
  double get accuracy;

  /// Create a copy of Statistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StatisticsImplCopyWith<_$StatisticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
