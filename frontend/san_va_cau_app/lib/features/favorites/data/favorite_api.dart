import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/favorite_item.dart';

class FavoriteApi {
  FavoriteApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<bool> checkFavorite(String targetType, String targetId) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Unauthenticated');
    }

    final response = await _apiClient.get(
      '/favorites/check',
      queryParameters: {'targetType': targetType, 'targetId': targetId},
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>;
    return data['isFavorited'] == true;
  }

  Future<void> addFavorite(String targetType, String targetId) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Vui lòng đăng nhập để yêu thích',
      );
    }

    await _apiClient.post(
      '/favorites',
      token: token,
      body: {'targetType': targetType, 'targetId': targetId},
    );
  }

  Future<void> removeFavorite(String targetType, String targetId) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Vui lòng đăng nhập để thao tác',
      );
    }

    await _apiClient.delete(
      '/favorites',
      queryParameters: {'targetType': targetType, 'targetId': targetId},
      token: token,
    );
  }

  Future<List<FavoriteItem>> getFavorites({
    String targetType = 'PRODUCT',
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Vui lòng đăng nhập để xem danh sách yêu thích',
      );
    }

    final response = await _apiClient.get(
      '/favorites',
      queryParameters: {'targetType': targetType},
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>;
    final itemsJson = data['items'] as List<dynamic>? ?? [];

    return itemsJson
        .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
