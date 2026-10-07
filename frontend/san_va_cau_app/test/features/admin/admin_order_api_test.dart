import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/orders/data/order_api.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.responseHandler);
  final Future<Map<String, dynamic>> Function(
    String method,
    String path, {
    String? token,
    Object? body,
    Map<String, String>? queryParameters,
  })
  responseHandler;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
    Map<String, String>? queryParameters,
  }) {
    return responseHandler(
      'GET',
      path,
      token: token,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<Map<String, dynamic>> patch(
    String path, {
    String? token,
    Object? body,
    Map<String, String>? queryParameters,
  }) {
    return responseHandler(
      'PATCH',
      path,
      token: token,
      body: body,
      queryParameters: queryParameters,
    );
  }
}

class _FakeTokenStorage extends TokenStorage {
  _FakeTokenStorage(this.token);
  final String? token;

  @override
  Future<String?> readToken() async => token;
}

void main() {
  group('AdminOrderApi', () {
    test('requires a token', () async {
      final api = OrderApi(
        apiClient: _FakeApiClient(
          (_, _, {body, queryParameters, token}) async => {},
        ),
        tokenStorage: _FakeTokenStorage(null),
      );

      expect(() => api.getAdminOrders(), throwsA(isA<ApiException>()));
      expect(() => api.getAdminOrderById('1'), throwsA(isA<ApiException>()));
      expect(
        () => api.updateAdminOrderStatus(id: '1', status: 'PENDING'),
        throwsA(isA<ApiException>()),
      );
    });

    test('getAdminOrders sends token and query parameters', () async {
      String? requestToken;
      Map<String, String>? requestQuery;

      final api = OrderApi(
        apiClient: _FakeApiClient((
          method,
          path, {
          body,
          queryParameters,
          token,
        }) async {
          requestToken = token;
          requestQuery = queryParameters;
          return {
            'data': {'orders': []},
          };
        }),
        tokenStorage: _FakeTokenStorage('fake-token'),
      );

      await api.getAdminOrders(branchId: '2', status: 'PENDING');

      expect(requestToken, 'fake-token');
      expect(requestQuery?['branchId'], '2');
      expect(requestQuery?['status'], 'PENDING');
      expect(requestQuery?.containsKey('customerId'), false);
    });

    test('getAdminOrders parses complex order correctly', () async {
      final api = OrderApi(
        apiClient: _FakeApiClient((_, _, {body, queryParameters, token}) async {
          return {
            'data': {
              'orders': [
                {
                  'id': '10',
                  'customerId': '99',
                  'branchId': '1',
                  'status': 'COMPLETED',
                  'totalAmount': '500000',
                  'createdAt': '2026-10-06T10:00:00Z',
                  'completedAt': '2026-10-06T11:00:00Z',
                  'customer': {
                    'id': '99',
                    'fullName': 'John Doe',
                    'phone': '0123456789',
                  },
                  'branch': {
                    'id': '1',
                    'name': 'Chi nhánh 1',
                    'address': 'Hanoi',
                  },
                  'items': [
                    {
                      'id': '1',
                      'productVariantId': '2',
                      'productName': 'Racket',
                      'variantName': 'Red',
                      'unitPrice': '500000',
                      'quantity': 1,
                      'imageUrl': 'http://image.com',
                    },
                  ],
                },
              ],
            },
          };
        }),
        tokenStorage: _FakeTokenStorage('token'),
      );

      final orders = await api.getAdminOrders();
      expect(orders.length, 1);

      final order = orders.first;
      expect(order.id, '10');
      expect(order.status, 'COMPLETED');
      expect(order.createdAt?.year, 2026);
      expect(order.completedAt?.year, 2026);
      expect(order.readyAt, null);

      expect(order.customer?.fullName, 'John Doe');
      expect(order.branch?.name, 'Chi nhánh 1');
      expect(order.items.first.productName, 'Racket');
    });

    test('getAdminOrderById uses correct path', () async {
      String? requestPath;
      final api = OrderApi(
        apiClient: _FakeApiClient((
          method,
          path, {
          body,
          queryParameters,
          token,
        }) async {
          requestPath = path;
          return {
            'data': {
              'order': {
                'id': '42',
                'customerId': '99',
                'branchId': '1',
                'status': 'PENDING',
                'totalAmount': '100',
                'createdAt': '2026-10-06T10:00:00Z',
              },
            },
          };
        }),
        tokenStorage: _FakeTokenStorage('token'),
      );

      final order = await api.getAdminOrderById('42');
      expect(requestPath, '/orders/42');
      expect(order.id, '42');
    });

    test('updateAdminOrderStatus uses correct path and body', () async {
      String? requestPath;
      Object? requestBody;
      final api = OrderApi(
        apiClient: _FakeApiClient((
          method,
          path, {
          body,
          queryParameters,
          token,
        }) async {
          requestPath = path;
          requestBody = body;
          return {
            'data': {
              'order': {
                'id': '42',
                'customerId': '99',
                'branchId': '1',
                'status': 'READY_FOR_PICKUP',
                'totalAmount': '100',
                'createdAt': '2026-10-06T10:00:00Z',
              },
            },
          };
        }),
        tokenStorage: _FakeTokenStorage('token'),
      );

      final order = await api.updateAdminOrderStatus(
        id: '42',
        status: 'ready_for_pickup',
      );
      expect(requestPath, '/orders/42/status');
      expect(requestBody, {'status': 'READY_FOR_PICKUP'});
      expect(order.status, 'READY_FOR_PICKUP');
    });

    test('propagates ApiException correctly', () async {
      final api = OrderApi(
        apiClient: _FakeApiClient((_, _, {body, queryParameters, token}) async {
          throw const ApiException(statusCode: 400, message: 'Invalid status');
        }),
        tokenStorage: _FakeTokenStorage('token'),
      );

      expect(
        () => api.updateAdminOrderStatus(id: '1', status: 'INVALID'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
