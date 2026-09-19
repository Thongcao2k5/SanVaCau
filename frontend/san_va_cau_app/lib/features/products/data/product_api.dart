import '../../../core/network/api_client.dart';
import '../models/product.dart';

class ProductApi {
  ProductApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Product>> getProducts() async {
    final response = await _apiClient.get('/products');
    final data = response['data'] as Map<String, dynamic>;
    final productsJson = data['products'] as List<dynamic>;

    return productsJson
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
