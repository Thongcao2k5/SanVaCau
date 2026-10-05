import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/notification_item.dart';

class NotificationApi {
  NotificationApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<List<NotificationItem>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Vui lòng đăng nhập để xem thông báo',
      );
    }

    final response = await _apiClient.get(
      '/notifications',
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>;
    final itemsJson = data['items'] as List<dynamic>? ?? [];

    return itemsJson
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Vui lòng đăng nhập');
    }

    await _apiClient.patch('/notifications/$id/read', token: token);
  }

  Future<void> markAllAsRead() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Vui lòng đăng nhập');
    }

    await _apiClient.patch('/notifications/read-all', token: token);
  }
}
