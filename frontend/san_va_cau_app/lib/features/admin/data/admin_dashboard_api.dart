import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/admin_dashboard.dart';

class AdminDashboardApi {
  AdminDashboardApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AdminDashboard> getSummary({String? date}) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }

    final response = await _apiClient.get(
      '/dashboard/summary',
      token: token,
      queryParameters: date == null ? null : {'date': date},
    );
    return AdminDashboard.fromJson(
      response['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }
}
