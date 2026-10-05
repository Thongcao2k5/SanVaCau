import '../../../core/network/api_client.dart';
import '../models/search_result.dart';

class SearchApi {
  SearchApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<SearchData> getSearchResults({
    required String query,
    String type = 'ALL',
    int page = 1,
    int limit = 20,
  }) async {
    if (query.trim().length < 2) {
      throw const ApiException(
        statusCode: 400,
        message: 'Từ khóa phải có ít nhất 2 ký tự',
      );
    }

    final queryParams = {
      'q': query.trim(),
      'type': type,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final response = await _apiClient.get(
      '/search',
      queryParameters: queryParams,
    );
    return SearchData.fromJson(response['data'] as Map<String, dynamic>);
  }
}
