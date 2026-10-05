import '../../../core/network/api_client.dart';
import '../models/news_article.dart';

class NewsApi {
  NewsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<NewsArticle>> getNews() async {
    final response = await _apiClient.get('/news');
    final data = response['data'] as Map<String, dynamic>;
    final newsJson = data['news'] as List<dynamic>? ?? [];

    return newsJson
        .map((item) => NewsArticle.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<NewsArticle> getNewsById(String id) async {
    final response = await _apiClient.get('/news/$id');
    final data = response['data'] as Map<String, dynamic>;

    return NewsArticle.fromJson(data['news'] as Map<String, dynamic>);
  }
}
