import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/admin_user.dart';

class AdminUserApi {
  AdminUserApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<List<AdminUser>> getUsers({int page = 1, int limit = 100}) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(statusCode: 401, message: 'Unauthorized');
    }

    final response = await _apiClient.get(
      '/auth/admin/users',
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      token: token,
    );

    final data = response['data'];
    if (data == null || data['users'] == null) {
      return [];
    }

    final List usersJson = data['users'] as List;
    return usersJson
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminUser> createUser({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String role,
    required String branchId,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(statusCode: 401, message: 'Unauthorized');
    }

    final response = await _apiClient.post(
      '/auth/admin/users',
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'role': role,
        'branchId': branchId,
      },
      token: token,
    );

    final data = response['data'];
    if (data == null || data['user'] == null) {
      throw const ApiException(
        statusCode: 500,
        message: 'Invalid response format',
      );
    }

    return AdminUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AdminUser> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(statusCode: 401, message: 'Unauthorized');
    }

    final response = await _apiClient.patch(
      '/auth/admin/users/$userId/status',
      body: {'status': status},
      token: token,
    );

    final data = response['data'];
    if (data == null || data['user'] == null) {
      throw const ApiException(
        statusCode: 500,
        message: 'Invalid response format',
      );
    }

    return AdminUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(statusCode: 401, message: 'Unauthorized');
    }

    await _apiClient.patch(
      '/auth/admin/users/$userId/password',
      body: {'newPassword': newPassword},
      token: token,
    );
  }
}
