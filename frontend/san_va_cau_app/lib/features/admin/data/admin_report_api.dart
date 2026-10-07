import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/admin_report.dart';

class AdminReportApi {
  AdminReportApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<String> _getToken() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }
    return token;
  }

  Future<AdminReportOverview> getOverview({String? from, String? to}) async {
    final token = await _getToken();
    final query = <String, String>{};
    if (from != null && from.isNotEmpty) query['from'] = from;
    if (to != null && to.isNotEmpty) query['to'] = to;

    final response = await _apiClient.get(
      '/reports/overview',
      token: token,
      queryParameters: query.isEmpty ? null : query,
    );
    return AdminReportOverview.fromJson(
      response['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  Future<List<AdminReportTopProduct>> getTopProducts({
    String? from,
    String? to,
    int limit = 5,
  }) async {
    final token = await _getToken();
    final query = <String, String>{'limit': limit.toString()};
    if (from != null && from.isNotEmpty) query['from'] = from;
    if (to != null && to.isNotEmpty) query['to'] = to;

    final response = await _apiClient.get(
      '/reports/top-products',
      token: token,
      queryParameters: query,
    );
    final rawData = response['data'];
    final data = rawData is List<dynamic> ? rawData : const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AdminReportTopProduct.fromJson)
        .toList();
  }

  Future<List<AdminReportTopCourt>> getTopCourts({
    String? from,
    String? to,
    int limit = 5,
  }) async {
    final token = await _getToken();
    final query = <String, String>{'limit': limit.toString()};
    if (from != null && from.isNotEmpty) query['from'] = from;
    if (to != null && to.isNotEmpty) query['to'] = to;

    final response = await _apiClient.get(
      '/reports/top-courts',
      token: token,
      queryParameters: query,
    );
    final rawData = response['data'];
    final data = rawData is List<dynamic> ? rawData : const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AdminReportTopCourt.fromJson)
        .toList();
  }
}
