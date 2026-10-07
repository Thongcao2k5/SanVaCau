import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/product.dart';
import '../models/product_variant.dart';

class ProductApi {
  ProductApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

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

  // Admin Product Methods
  Future<Product> createAdminProduct(Map<String, dynamic> body) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập hết hạn',
      );
    }
    final response = await _apiClient.post(
      '/products',
      body: body,
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  Future<Product> updateAdminProduct(
    String id,
    Map<String, dynamic> body,
  ) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập hết hạn',
      );
    }
    final response = await _apiClient.patch(
      '/products/$id',
      body: body,
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>;
    return Product.fromJson(data['product'] as Map<String, dynamic>);
  }

  Future<void> inactivateAdminProduct(String id) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập hết hạn',
      );
    }
    await _apiClient.patch('/products/$id/inactivate', token: token);
  }

  // Admin Variant Methods
  Future<ProductVariant> createAdminVariant(Map<String, dynamic> body) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập hết hạn',
      );
    }
    final response = await _apiClient.post(
      '/product-variants',
      body: body,
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ProductVariant.fromJson(data['variant'] as Map<String, dynamic>);
  }

  Future<ProductVariant> updateAdminVariant(
    String id,
    Map<String, dynamic> body,
  ) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập hết hạn',
      );
    }
    final response = await _apiClient.patch(
      '/product-variants/$id',
      body: body,
      token: token,
    );
    final data = response['data'] as Map<String, dynamic>;
    return ProductVariant.fromJson(data['variant'] as Map<String, dynamic>);
  }

  Future<void> inactivateAdminVariant(String id) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập hết hạn',
      );
    }
    await _apiClient.patch('/product-variants/$id/inactivate', token: token);
  }
}
