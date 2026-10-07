import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/admin/data/admin_inventory_api.dart';

class MockTokenStorage extends TokenStorage {
  String? mockToken = 'mock_token';

  @override
  Future<String?> readToken() async => mockToken;
}

class MockApiClient extends ApiClient {
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  Map<String, String>? lastQuery;
  String? lastToken;

  bool shouldThrow = false;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    lastQuery = queryParameters;
    lastToken = token;

    if (shouldThrow) {
      throw const ApiException(statusCode: 500, message: 'Server Error');
    }

    if (path.startsWith('/inventories/')) {
      return {
        'data': {
          'inventory': {
            'id': 'inv1',
            'branchId': 'b1',
            'productVariantId': 'v1',
            'quantity': 10,
          },
        },
      };
    }

    return {
      'data': {
        'inventories': [
          {
            'id': 'inv1',
            'branchId': 'b1',
            'productVariantId': 'v1',
            'quantity': 10,
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
    lastToken = token;

    if (shouldThrow) {
      throw const ApiException(statusCode: 500, message: 'Server Error');
    }

    return {
      'data': {
        'inventory': {
          'id': 'inv2',
          'branchId': lastBody?['branchId'] ?? 'b1',
          'productVariantId': lastBody?['productVariantId'] ?? 'v1',
          'quantity': lastBody?['quantity'] ?? 0,
        },
      },
    };
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    lastMethod = 'PATCH';
    lastPath = path;
    lastBody = body;
    lastToken = token;

    if (shouldThrow) {
      throw const ApiException(statusCode: 500, message: 'Server Error');
    }

    return {
      'data': {
        'inventory': {
          'id': 'inv1',
          'branchId': 'b1',
          'productVariantId': 'v1',
          'quantity': lastBody?['quantity'] ?? 0,
        },
      },
    };
  }
}

void main() {
  group('Admin Inventory Api Tests', () {
    late MockApiClient mockApi;
    late MockTokenStorage mockToken;
    late AdminInventoryApi api;

    setUp(() {
      mockApi = MockApiClient();
      mockToken = MockTokenStorage();
      api = AdminInventoryApi(apiClient: mockApi, tokenStorage: mockToken);
    });

    test('missing token throws 401', () async {
      mockToken.mockToken = null;
      expect(
        () => api.getInventories(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(() => api.getInventoryById('id'), throwsA(isA<ApiException>()));
      expect(
        () => api.createInventory(
          branchId: 'b',
          productVariantId: 'v',
          quantity: 1,
        ),
        throwsA(isA<ApiException>()),
      );
      expect(
        () => api.updateInventoryQuantity(inventoryId: 'i', quantity: 1),
        throwsA(isA<ApiException>()),
      );
    });

    test('getInventories uses exact GET path and queryParameters', () async {
      await api.getInventories(branchId: 'b1', productVariantId: 'v1');
      expect(mockApi.lastPath, '/inventories');
      expect(mockApi.lastQuery, {'branchId': 'b1', 'productVariantId': 'v1'});
      expect(mockApi.lastToken, 'mock_token');
      expect(mockApi.lastMethod, 'GET');
    });

    test('getInventoryById uses exact GET detail path', () async {
      await api.getInventoryById('inv1');
      expect(mockApi.lastPath, '/inventories/inv1');
      expect(mockApi.lastMethod, 'GET');
    });

    test('createInventory uses exact POST path and body', () async {
      final res = await api.createInventory(
        branchId: 'b1',
        productVariantId: 'v1',
        quantity: 5,
      );
      expect(mockApi.lastPath, '/inventories');
      expect(mockApi.lastMethod, 'POST');
      expect(mockApi.lastBody, {
        'branchId': 'b1',
        'productVariantId': 'v1',
        'quantity': 5,
      });
      expect(res.quantity, 5);
    });

    test('updateInventoryQuantity uses exact PATCH path and body', () async {
      final res = await api.updateInventoryQuantity(
        inventoryId: 'inv1',
        quantity: 100,
      );
      expect(mockApi.lastPath, '/inventories/inv1');
      expect(mockApi.lastMethod, 'PATCH');
      expect(mockApi.lastBody, {'quantity': 100});
      expect(res.quantity, 100);
    });

    test('backend error propagation', () async {
      mockApi.shouldThrow = true;
      expect(
        () => api.getInventories(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Server Error',
          ),
        ),
      );
    });
  });
}
