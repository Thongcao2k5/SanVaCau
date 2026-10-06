import '../../../core/network/api_client.dart';
import '../models/product.dart';
import '../models/product_variant.dart';

class ProductApi {
  ProductApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Product>> getProducts({
    String? categoryId,
    String? brandId,
  }) async {
    final response = await _apiClient.get(
      '/products',
      queryParameters: {
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (brandId != null && brandId.isNotEmpty) 'brandId': brandId,
      },
    );
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

  Future<List<ProductCategory>> getCategories() async {
    final response = await _apiClient.get('/categories');
    final data = response['data'] as Map<String, dynamic>;
    final categoriesJson = data['categories'] as List<dynamic>? ?? [];
    return _flattenCategories(categoriesJson);
  }

  Future<List<ProductBrand>> getBrands() async {
    final response = await _apiClient.get('/brands');
    final data = response['data'] as Map<String, dynamic>;
    final brandsJson = data['brands'] as List<dynamic>? ?? [];
    return brandsJson
        .whereType<Map<String, dynamic>>()
        .map(ProductBrand.fromJson)
        .toList();
  }

  List<ProductCategory> _flattenCategories(List<dynamic> nodes) {
    final categories = <ProductCategory>[];
    for (final node in nodes.whereType<Map<String, dynamic>>()) {
      categories.add(ProductCategory.fromJson(node));
      final children = node['children'] as List<dynamic>? ?? [];
      categories.addAll(_flattenCategories(children));
    }
    return categories;
  }
}
