class UserModel {
  final String id;
  final String displayName;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
    );
  }
}
