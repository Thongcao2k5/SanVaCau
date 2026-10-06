import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/cart.dart';

class CartApi {
  CartApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<Cart> getCart() async {
    final response = await _apiClient.get('/cart', token: await _readToken());
    final data = response['data'] as Map<String, dynamic>;

    return Cart.fromJson(data['cart'] as Map<String, dynamic>);
  }

  Future<Cart> addItem({
    required String productVariantId,
    required int quantity,
  }) async {
    final response = await _apiClient.post(
      '/cart/items',
      token: await _readToken(),
      body: {'productVariantId': productVariantId, 'quantity': quantity},
    );
    final data = response['data'] as Map<String, dynamic>;

    return Cart.fromJson(data['cart'] as Map<String, dynamic>);
  }

  Future<Cart> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    final response = await _apiClient.patch(
      '/cart/items/$itemId',
      token: await _readToken(),
      body: {'quantity': quantity},
    );
    final data = response['data'] as Map<String, dynamic>;

    return Cart.fromJson(data['cart'] as Map<String, dynamic>);
  }

  Future<Cart> removeItem(String itemId) async {
    final response = await _apiClient.delete(
      '/cart/items/$itemId',
      token: await _readToken(),
    );
    final data = response['data'] as Map<String, dynamic>;

    return Cart.fromJson(data['cart'] as Map<String, dynamic>);
  }

  Future<Cart> clearCart() async {
    final response = await _apiClient.delete(
      '/cart',
      token: await _readToken(),
    );
    final data = response['data'] as Map<String, dynamic>;

    return Cart.fromJson(data['cart'] as Map<String, dynamic>);
  }

  Future<String> _readToken() async {
    final token = await _tokenStorage.readToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }

    return token;
  }
}
