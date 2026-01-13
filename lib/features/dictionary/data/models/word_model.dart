class WordModel {
  final String id;
  final String text;
  final String description;
  final String? videoUrl;
  bool favorite;

  WordModel({
    required this.id,
    required this.text,
    required this.description,
    this.videoUrl,
    required this.favorite,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'],
      text: json['text'],
      description: json['description'],
      videoUrl: json['videoUrl'],
      favorite: json['favorite'],
    );
  }
}
