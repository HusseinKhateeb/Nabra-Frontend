import 'word_model.dart';

class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final List<WordModel> words;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.words,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      words: (json['words'] as List<dynamic>? ?? const [])
          .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
