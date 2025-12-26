import 'package:equatable/equatable.dart';

class AuthTokens extends Equatable {
  const AuthTokens({required this.accessToken});

  final String accessToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(accessToken: (json['accessToken'] ?? '') as String);
  }

  @override
  List<Object?> get props => [accessToken];
}
