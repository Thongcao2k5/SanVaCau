import '../../../core/network/api_client.dart';
import '../models/news_article.dart';

class NewsApi {
  NewsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<NewsArticle>> getNews() async {
    final response = await _apiClient.get(
      '/news',
      queryParameters: const {'status': 'PUBLISHED', 'limit': '50'},
    );
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final items = data['news'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(NewsArticle.fromJson)
        .toList();
  }

  Future<NewsArticle> getNewsById(String id) async {
    final response = await _apiClient.get('/news/$id');
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final item = data['news'] as Map<String, dynamic>?;
    if (item == null) {
      throw const ApiException(
        statusCode: 500,
        message: 'Dữ liệu tin tức không hợp lệ.',
      );
    }
    return NewsArticle.fromJson(item);
  }
}
