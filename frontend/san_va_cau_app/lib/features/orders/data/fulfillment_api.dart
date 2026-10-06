import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/order_fulfillment.dart';

class FulfillmentApi {
  FulfillmentApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<OrderFulfillment> createPickup({required String orderId}) {
    return _create(orderId: orderId, body: const {'fulfillmentType': 'PICKUP'});
  }

  Future<OrderFulfillment> createDelivery({
    required String orderId,
    required String addressId,
  }) {
    return _create(
      orderId: orderId,
      body: {'fulfillmentType': 'DELIVERY', 'addressId': addressId},
    );
  }

  Future<OrderFulfillment?> getForOrder(String orderId) async {
    try {
      final response = await _apiClient.get(
        '/fulfillments/orders/$orderId',
        token: await _token(),
      );
      return _fromResponse(response);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<OrderFulfillment> _create({
    required String orderId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _apiClient.post(
      '/fulfillments/orders/$orderId',
      token: await _token(),
      body: body,
    );
    return _fromResponse(response);
  }

  Future<String> _token() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }
    return token;
  }

  OrderFulfillment _fromResponse(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    final fulfillment = data['fulfillment'] as Map<String, dynamic>?;
    if (fulfillment == null) {
      throw const ApiException(
        statusCode: 500,
        message: 'Dữ liệu giao nhận không hợp lệ.',
      );
    }
    return OrderFulfillment.fromJson(fulfillment);
  }
}
