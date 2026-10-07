import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/admin_content.dart';
import '../../notifications/models/notification_item.dart';

class AdminContentApi {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  AdminContentApi({ApiClient? client, TokenStorage? tokenStorage})
    : _client = client ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<String> _getToken() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw ApiException(
        statusCode: 401,
        message: 'Không tìm thấy phiên đăng nhập. Vui lòng đăng nhập lại.',
      );
    }
    return token;
  }

  // --- NEWS ---

  Future<List<AdminNewsArticle>> getNews({
    required String status,
    int limit = 50,
  }) async {
    final token = await _getToken();
    final response = await _client.get(
      '/news',
      queryParameters: {'status': status, 'limit': limit.toString()},
      token: token,
    );

    final data = response['data']?['news'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => AdminNewsArticle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminNewsArticle> createNews({
    required String title,
    required String content,
    String? summary,
    String? thumbnailUrl,
    String? branchId,
  }) async {
    final token = await _getToken();
    final response = await _client.post(
      '/news',
      body: {
        'title': title,
        'content': content,
        'summary': summary,
        'thumbnailUrl': thumbnailUrl,
        'branchId': branchId,
      },
      token: token,
    );
    return AdminNewsArticle.fromJson(
      response['data']['news'] as Map<String, dynamic>,
    );
  }

  Future<AdminNewsArticle> updateNews({
    required String id,
    required String title,
    required String content,
    String? summary,
    String? thumbnailUrl,
    String? branchId,
  }) async {
    final token = await _getToken();
    final response = await _client.patch(
      '/news/$id',
      body: {
        'title': title,
        'content': content,
        'summary': summary,
        'thumbnailUrl': thumbnailUrl,
        'branchId': branchId,
      },
      token: token,
    );
    return AdminNewsArticle.fromJson(
      response['data']['news'] as Map<String, dynamic>,
    );
  }

  Future<AdminNewsArticle> publishNews(String id) async {
    final token = await _getToken();
    final response = await _client.patch('/news/$id/publish', token: token);
    return AdminNewsArticle.fromJson(
      response['data']['news'] as Map<String, dynamic>,
    );
  }

  Future<AdminNewsArticle> archiveNews(String id) async {
    final token = await _getToken();
    final response = await _client.patch('/news/$id/archive', token: token);
    return AdminNewsArticle.fromJson(
      response['data']['news'] as Map<String, dynamic>,
    );
  }

  // --- BANNERS ---

  Future<List<AdminBanner>> getBanners() async {
    // Note: GET /api/banners is public and only returns active, unexpired banners
    final response = await _client.get('/banners');
    final data = response['data']?['banners'] as List<dynamic>?;
    if (data == null) return [];
    return data
        .map((e) => AdminBanner.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminBanner> createBanner({
    String? title,
    required String imageUrl,
    String? linkUrl,
    int sortOrder = 0,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    final token = await _getToken();
    final response = await _client.post(
      '/banners',
      body: {
        'title': title,
        'imageUrl': imageUrl,
        'linkUrl': linkUrl,
        'sortOrder': sortOrder,
        'startAt': startAt?.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
      },
      token: token,
    );
    return AdminBanner.fromJson(
      response['data']['banner'] as Map<String, dynamic>,
    );
  }

  Future<AdminBanner> updateBanner({
    required String id,
    String? title,
    required String imageUrl,
    String? linkUrl,
    required int sortOrder,
    DateTime? startAt,
    DateTime? endAt,
    bool? isActive,
  }) async {
    final token = await _getToken();
    final response = await _client.patch(
      '/banners/$id',
      body: {
        'title': title,
        'imageUrl': imageUrl,
        'linkUrl': linkUrl,
        'sortOrder': sortOrder,
        'startAt': startAt?.toIso8601String(),
        'endAt': endAt?.toIso8601String(),
        'isActive': ?isActive,
      },
      token: token,
    );
    return AdminBanner.fromJson(
      response['data']['banner'] as Map<String, dynamic>,
    );
  }

  Future<AdminBanner> inactivateBanner(String id) async {
    final token = await _getToken();
    final response = await _client.patch(
      '/banners/$id/inactivate',
      token: token,
    );
    return AdminBanner.fromJson(
      response['data']['banner'] as Map<String, dynamic>,
    );
  }

  // --- NOTIFICATIONS ---

  Future<NotificationItem> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
  }) async {
    final token = await _getToken();
    final response = await _client.post(
      '/notifications/admin',
      body: {
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
      },
      token: token,
    );
    return NotificationItem.fromJson(
      response['data']['notification'] as Map<String, dynamic>,
    );
  }
}
