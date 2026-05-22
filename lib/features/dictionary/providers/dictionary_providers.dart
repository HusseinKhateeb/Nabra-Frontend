import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../data/dictionary_api.dart';
import '../data/models/category_model.dart';
import '../data/models/word_model.dart';

/// =======================
/// API Provider
/// =======================
final dictionaryApiProvider = Provider<DictionaryApi>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return DictionaryApi(dioClient);
});

/// =======================
/// Categories
/// =======================
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final api = ref.read(dictionaryApiProvider);
  final data = await api.getCategories();

  return data
      .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// =======================
/// Selected Category
/// =======================
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// =======================
/// Search
/// =======================
final searchQueryProvider = StateProvider<String>((ref) => "");

/// =======================
/// Words
/// =======================
final wordsProvider =
    FutureProvider.family<List<WordModel>, String>((ref, categoryId) async {
  final api = ref.read(dictionaryApiProvider);
  final data = await api.getWords(categoryId);

  return data
      .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// =======================
/// Toggle Favorite ⭐
/// =======================
final toggleFavoriteProvider =
    FutureProvider.family<bool, WordModel>((ref, word) async {
  final api = ref.read(dictionaryApiProvider);

  await api.toggleFavorite(word.id, word.favorite);

  // نرجع القيمة الجديدة
  return !word.favorite;
});

/// =======================
/// Favorite Words ❤️
/// =======================
final favoriteWordsProvider = FutureProvider<List<WordModel>>((ref) async {
  final api = ref.read(dictionaryApiProvider);
  final data = await api.getFavoriteWords();

  return data
      .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
