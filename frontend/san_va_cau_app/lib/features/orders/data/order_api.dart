import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/order.dart';

class OrderApi {
  OrderApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<Order> createOrder({required String branchId}) async {
    final response = await _apiClient.post(
      '/orders',
      token: await _readToken(),
      body: {'branchId': branchId},
    );
    final data = response['data'] as Map<String, dynamic>;

    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  Future<List<Order>> getMyOrders() async {
    final response = await _apiClient.get(
      '/orders/me',
      token: await _readToken(),
    );
    final data = response['data'] as Map<String, dynamic>;
    final ordersJson = data['orders'] as List<dynamic>;

    return ordersJson
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Order> getMyOrderById(String id) async {
    final response = await _apiClient.get(
      '/orders/me/$id',
      token: await _readToken(),
    );
    final data = response['data'] as Map<String, dynamic>;

    return Order.fromJson(data['order'] as Map<String, dynamic>);
  }

  Future<String> _readToken() async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }

    return token;
  }
}
