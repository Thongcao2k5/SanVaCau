import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/admin_inventory.dart';

class AdminInventoryApi {
  AdminInventoryApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<List<AdminInventory>> getInventories({
    String? branchId,
    String? productVariantId,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập hết hạn',
      );
    }

    final queryParameters = <String, String>{};
    if (branchId != null && branchId.isNotEmpty) {
      queryParameters['branchId'] = branchId;
    }
    if (productVariantId != null && productVariantId.isNotEmpty) {
      queryParameters['productVariantId'] = productVariantId;
    }

    final response = await _apiClient.get(
      '/inventories',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      token: token,
    );

    final data = response['data'] as Map<String, dynamic>;
    final list = data['inventories'] as List<dynamic>? ?? [];

    return list
        .map((item) => AdminInventory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminInventory> getInventoryById(String id) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập hết hạn',
      );
    }

    final response = await _apiClient.get('/inventories/$id', token: token);

    final data = response['data'] as Map<String, dynamic>;
    return AdminInventory.fromJson(data['inventory'] as Map<String, dynamic>);
  }

  Future<AdminInventory> createInventory({
    required String branchId,
    required String productVariantId,
    required int quantity,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập hết hạn',
      );
    }

    final response = await _apiClient.post(
      '/inventories',
      body: {
        'branchId': branchId,
        'productVariantId': productVariantId,
        'quantity': quantity,
      },
      token: token,
    );

    final data = response['data'] as Map<String, dynamic>;
    return AdminInventory.fromJson(data['inventory'] as Map<String, dynamic>);
  }

  Future<AdminInventory> updateInventoryQuantity({
    required String inventoryId,
    required int quantity,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      throw const ApiException(
        statusCode: 401,
        message: 'Phiên đăng nhập hết hạn',
      );
    }

    final response = await _apiClient.patch(
      '/inventories/$inventoryId',
      body: {'quantity': quantity},
      token: token,
    );

    final data = response['data'] as Map<String, dynamic>;
    return AdminInventory.fromJson(data['inventory'] as Map<String, dynamic>);
  }
}
