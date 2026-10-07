import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/products/data/product_api.dart';

class FakeTokenStorage implements TokenStorage {
  String? token = 'fake-token';

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String newToken) async => token = newToken;

  @override
  Future<void> clearToken() async => token = null;
}

class FakeApiClient implements ApiClient {
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  String? lastToken;

  Object? nextResponse;
  Object? nextError;

  @override
  String get baseUrl => '';

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    lastToken = token;
    if (nextError != null) throw nextError!;
    return nextResponse as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
    lastToken = token;
    if (nextError != null) throw nextError!;
    return nextResponse as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    lastMethod = 'PATCH';
    lastPath = path;
    lastBody = body;
    lastToken = token;
    if (nextError != null) throw nextError!;
    return nextResponse as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? queryParameters,
    String? token,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Admin Product Api Tests', () {
    late FakeApiClient apiClient;
    late FakeTokenStorage tokenStorage;
    late ProductApi productApi;

    setUp(() {
      apiClient = FakeApiClient();
      tokenStorage = FakeTokenStorage();
      productApi = ProductApi(apiClient: apiClient, tokenStorage: tokenStorage);
    });

    test('missing token throws 401', () async {
      tokenStorage.token = null;
      expect(
        () => productApi.createAdminProduct({}),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(
        () => productApi.updateAdminProduct('1', {}),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(
        () => productApi.inactivateAdminProduct('1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(
        () => productApi.createAdminVariant({}),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(
        () => productApi.updateAdminVariant('1', {}),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(
        () => productApi.inactivateAdminVariant('1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('createAdminProduct uses exact POST path and exact body', () async {
      apiClient.nextResponse = {
        'success': true,
        'data': {
          'product': {
            'id': '123',
            'categoryId': 'c1',
            'name': 'P1',
            'isActive': true,
            'isFeatured': false,
            'category': {'id': 'c1', 'name': 'C1'},
          },
        },
      };

      final body = {
        'categoryId': 'c1',
        'brandId': null,
        'name': 'P1',
        'description': null,
        'imageUrl': null,
        'isFeatured': false,
      };

      final p = await productApi.createAdminProduct(body);

      expect(apiClient.lastMethod, 'POST');
      expect(apiClient.lastPath, '/products');
      expect(apiClient.lastToken, 'fake-token');
      expect(apiClient.lastBody, body);
      expect(p.id, '123');
      expect(p.name, 'P1');
    });

    test(
      'updateAdminProduct uses exact PATCH path and exact body including nulls',
      () async {
        apiClient.nextResponse = {
          'success': true,
          'data': {
            'product': {
              'id': '123',
              'categoryId': 'c1',
              'name': 'P1',
              'isActive': true,
              'isFeatured': false,
              'category': {'id': 'c1', 'name': 'C1'},
            },
          },
        };

        final body = {
          'categoryId': 'c1',
          'brandId': null,
          'name': 'P1',
          'description': null,
          'imageUrl': null,
          'isActive': true,
          'isFeatured': false,
        };

        final p = await productApi.updateAdminProduct('123', body);

        expect(apiClient.lastMethod, 'PATCH');
        expect(apiClient.lastPath, '/products/123');
        expect(apiClient.lastToken, 'fake-token');
        expect(apiClient.lastBody, body);
        expect(p.id, '123');
      },
    );

    test('inactivateAdminProduct uses exact PATCH path', () async {
      apiClient.nextResponse = {'success': true};

      await productApi.inactivateAdminProduct('123');

      expect(apiClient.lastMethod, 'PATCH');
      expect(apiClient.lastPath, '/products/123/inactivate');
      expect(apiClient.lastToken, 'fake-token');
    });

    test('createAdminVariant uses exact POST path and exact body including decimal prices', () async {
      apiClient.nextResponse = {
        'success': true,
        'data': {
          'variant': {
            'id': 'v1',
            'productId': 'p1',
            'sku': 'SKU1',
            'variantName': 'V1',
            'price': '100.5',
            'isActive': true,
          },
        },
      };

      final body = {
        'productId': 'p1',
        'sku': 'SKU1',
        'variantName': 'V1',
        'price': 100.5,
        'imageUrl': null,
      };

      final v = await productApi.createAdminVariant(body);

      expect(apiClient.lastMethod, 'POST');
      expect(apiClient.lastPath, '/product-variants');
      expect(apiClient.lastToken, 'fake-token');
      expect(apiClient.lastBody, body);
      expect(v.id, 'v1');
      expect(v.price, '100.5'); // safe string parsing
    });

    test('updateAdminVariant uses exact PATCH path', () async {
      apiClient.nextResponse = {
        'success': true,
        'data': {
          'variant': {
            'id': 'v1',
            'productId': 'p1',
            'sku': 'SKU1',
            'variantName': 'V1',
            'price': '100.5',
            'isActive': true,
          },
        },
      };

      final body = {
        'productId': 'p1',
        'sku': 'SKU1',
        'variantName': 'V1',
        'price': 100.5,
        'imageUrl': null,
        'isActive': true,
      };

      final v = await productApi.updateAdminVariant('v1', body);

      expect(apiClient.lastMethod, 'PATCH');
      expect(apiClient.lastPath, '/product-variants/v1');
      expect(apiClient.lastToken, 'fake-token');
      expect(apiClient.lastBody, body);
      expect(v.id, 'v1');
    });

    test('inactivateAdminVariant uses exact PATCH path', () async {
      apiClient.nextResponse = {'success': true};

      await productApi.inactivateAdminVariant('v1');

      expect(apiClient.lastMethod, 'PATCH');
      expect(apiClient.lastPath, '/product-variants/v1/inactivate');
      expect(apiClient.lastToken, 'fake-token');
    });

    test('backend error propagation', () async {
      apiClient.nextError = const ApiException(
        statusCode: 409,
        message: 'SKU đã tồn tại',
      );

      expect(
        () => productApi.createAdminVariant({}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'SKU đã tồn tại',
          ),
        ),
      );
    });
  });
}
