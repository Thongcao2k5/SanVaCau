import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/voucher_quote.dart';

class VoucherApi {
  VoucherApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<VoucherQuote> validateOrderVoucher({
    required String code,
    required double amount,
  }) async {
    final response = await _apiClient.post(
      '/vouchers/validate',
      token: await _token(),
      body: {'code': code.trim(), 'targetType': 'ORDER', 'amount': amount},
    );
    return _quote(response);
  }

  Future<VoucherQuote> applyOrderVoucher({
    required String code,
    required String orderId,
    required double amount,
  }) async {
    final response = await _apiClient.post(
      '/vouchers/apply',
      token: await _token(),
      body: {
        'code': code.trim(),
        'targetType': 'ORDER',
        'targetId': orderId,
        'amount': amount,
      },
    );
    return _quote(response);
  }

  VoucherQuote _quote(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const ApiException(
        statusCode: 500,
        message: 'Dữ liệu voucher không hợp lệ.',
      );
    }
    return VoucherQuote.fromJson(data);
  }

  Future<String> _token() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Vui lòng đăng nhập để sử dụng voucher.',
      );
    }
    return token;
  }
}
