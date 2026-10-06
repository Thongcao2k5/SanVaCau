import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/payment.dart';

class PaymentApi {
  PaymentApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<Payment> createPayment({
    required String targetType,
    required String targetId,
    required String provider,
  }) async {
    final response = await _apiClient.post(
      '/payments/mock',
      token: await _token(),
      body: {
        'targetType': targetType,
        'targetId': targetId,
        'provider': provider,
      },
    );
    return _fromData(response['data']);
  }

  Future<Payment> markSuccess(String paymentId) async {
    final response = await _apiClient.patch(
      '/payments/$paymentId/mock-success',
      token: await _token(),
    );
    return _fromData(response['data']);
  }

  Future<Payment> markFailed(String paymentId) async {
    final response = await _apiClient.patch(
      '/payments/$paymentId/mock-fail',
      token: await _token(),
    );
    return _fromData(response['data']);
  }

  Future<List<Payment>> getMyPayments() async {
    final response = await _apiClient.get(
      '/payments/me',
      token: await _token(),
      queryParameters: const {'page': '1', 'limit': '100'},
    );
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final items = data['items'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(Payment.fromJson)
        .toList();
  }

  Future<String> _token() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }
    return token;
  }

  Payment _fromData(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        statusCode: 500,
        message: 'Dữ liệu thanh toán không hợp lệ.',
      );
    }
    return Payment.fromJson(data);
  }
}
