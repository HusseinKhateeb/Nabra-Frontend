import '../../../core/network/dio_client.dart';
import '../../../core/config/api_endpoints.dart';


class DictionaryApi {
  DictionaryApi(this._client);

  final DioClient _client;

  Future<List<dynamic>> getCategories() async {
    final res = await _client.get(
      '${ApiEndpoints.dictionary}/categories',
    );
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getWords(String categoryId) async {
    final res = await _client.get(
      '${ApiEndpoints.dictionary}/categories/$categoryId/words',
    );
    return res.data as List<dynamic>;
  }

  Future<void> toggleFavorite(String wordId, bool isFav) async {
    if (isFav) {
      await _client.delete(
        '${ApiEndpoints.dictionary}/favorites/$wordId',
      );
    } else {
      await _client.post(
        '${ApiEndpoints.dictionary}/favorites/$wordId',
      );
    }
  }
}
