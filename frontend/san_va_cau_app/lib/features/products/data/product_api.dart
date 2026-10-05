import '../../../core/network/api_client.dart';
import '../models/product.dart';
import '../models/product_variant.dart';

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

  Future<Product> getProductById(String id) async {
    final response = await _apiClient.get('/products/$id');
    final data = response['data'] as Map<String, dynamic>;

    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  Future<List<ProductVariant>> getProductVariants(String productId) async {
    final response = await _apiClient.get(
      '/product-variants',
      queryParameters: {'productId': productId},
    );
    final data = response['data'] as Map<String, dynamic>;
    final variantsJson = data['variants'] as List<dynamic>;

    return variantsJson
        .map((item) => ProductVariant.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
