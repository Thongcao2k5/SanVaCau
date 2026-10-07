import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/admin/data/admin_dashboard_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'admin-token'});
  });

  test('loads and parses admin dashboard summary', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/dashboard/summary');
      expect(request.url.queryParameters, {'date': '2026-10-06'});
      expect(request.headers['authorization'], 'Bearer admin-token');

      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'scope': {'role': 'ADMIN', 'branchId': null},
            'date': '2026-10-06',
            'bookings': {
              'total': 4,
              'booked': 2,
              'checkedIn': 1,
              'completed': 1,
              'cancelled': 0,
            },
            'orders': {
              'total': 3,
              'pending': 1,
              'readyForPickup': 1,
              'completed': 1,
              'cancelled': 0,
              'revenueCompleted': '450000',
            },
            'inventory': {
              'lowStockCount': 1,
              'lowStockItems': [
                {
                  'inventoryId': '8',
                  'branchName': 'Chi nhánh 1',
                  'productName': 'Vợt Yonex',
                  'variantName': '4U',
                  'sku': 'YONEX-4U',
                  'quantity': 2,
                },
              ],
            },
            'courts': {'active': 5, 'maintenance': 1, 'inactive': 0},
            'latestBookings': [],
            'latestOrders': [],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = AdminDashboardApi(
      apiClient: ApiClient(httpClient: client, baseUrl: 'http://localhost/api'),
      tokenStorage: TokenStorage(),
    );

    final dashboard = await api.getSummary(date: '2026-10-06');

    expect(dashboard.role, 'ADMIN');
    expect(dashboard.bookings.total, 4);
    expect(dashboard.orders.revenueCompleted, 450000);
    expect(dashboard.inventory.lowStockItems.single.sku, 'YONEX-4U');
  });

  test('requires a token', () async {
    SharedPreferences.setMockInitialValues({});
    final api = AdminDashboardApi();

    await expectLater(api.getSummary(), throwsA(isA<ApiException>()));
  });

  test('handles malformed optional data', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'scope': {'role': 'STAFF'}, // missing branchId
            'date': null, // missing date
            'bookings': {}, // missing fields, should fallback to 0
            'orders': {}, // missing fields, should fallback to 0
            'inventory': {
              'lowStockCount': 0,
              'lowStockItems': [
                {
                  'inventoryId': null,
                  'branchName': null,
                  'quantity': 'not_a_number',
                },
              ],
            },
            'courts': {},
            'latestBookings': [
              {
                'id': 1,
                'customer': null, // optional customer
                'court': null,
              },
            ],
            'latestOrders': [
              {'id': 2, 'createdAt': 'invalid_date'},
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = AdminDashboardApi(
      apiClient: ApiClient(httpClient: client, baseUrl: 'http://localhost/api'),
      tokenStorage: TokenStorage(),
    );

    final dashboard = await api.getSummary();

    expect(dashboard.role, 'STAFF');
    expect(dashboard.branchId, isNull);
    expect(dashboard.date, '');
    expect(dashboard.bookings.total, 0);
    expect(dashboard.orders.revenueCompleted, 0);
    expect(dashboard.inventory.lowStockItems.length, 1);
    expect(dashboard.inventory.lowStockItems[0].id, '');
    expect(dashboard.inventory.lowStockItems[0].quantity, 0);
    expect(dashboard.latestBookings.length, 1);
    expect(dashboard.latestBookings[0].customerName, '');
    expect(dashboard.latestOrders.length, 1);
    expect(dashboard.latestOrders[0].createdAt, isNull);
  });
}
