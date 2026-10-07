import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/admin/data/admin_report_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'admin-token'});
  });

  group('AdminReportApi', () {
    test('getOverview calls correct endpoint and parses response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/reports/overview');
        expect(request.url.queryParameters, {
          'from': '2026-10-01',
          'to': '2026-10-31',
        });
        expect(request.headers['authorization'], 'Bearer admin-token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'totalOrders': 10,
              'totalOrderRevenue': '150000',
              'totalBookings': 5,
              'totalBookingRevenue': '50000.5',
              'totalPayments': 15,
              'totalPaidAmount': 200000,
              'totalCustomers': 20,
              'totalSupportTickets': 3,
              'openSupportTickets': 1,
              'resolvedSupportTickets': 2,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = AdminReportApi(
        apiClient: ApiClient(
          httpClient: client,
          baseUrl: 'http://localhost/api',
        ),
        tokenStorage: TokenStorage(),
      );

      final result = await api.getOverview(
        from: '2026-10-01',
        to: '2026-10-31',
      );

      expect(result.totalOrders, 10);
      expect(result.totalOrderRevenue, 150000.0);
      expect(result.totalBookings, 5);
      expect(result.totalBookingRevenue, 50000.5);
      expect(result.totalPayments, 15);
      expect(result.totalPaidAmount, 200000.0);
      expect(result.totalCustomers, 20);
      expect(result.totalSupportTickets, 3);
      expect(result.openSupportTickets, 1);
      expect(result.resolvedSupportTickets, 2);
    });

    for (final token in <String?>[null, '']) {
      test('missing token "$token" fails before an HTTP request', () async {
        SharedPreferences.setMockInitialValues(
          token == null ? {} : {'auth_token': token},
        );
        var requestCount = 0;
        final api = AdminReportApi(
          apiClient: ApiClient(
            httpClient: MockClient((request) async {
              requestCount++;
              return http.Response('{}', 200);
            }),
            baseUrl: 'http://localhost/api',
          ),
          tokenStorage: TokenStorage(),
        );

        await expectLater(
          api.getOverview(),
          throwsA(
            isA<ApiException>()
                .having((error) => error.statusCode, 'statusCode', 401)
                .having(
                  (error) => error.message,
                  'message',
                  'Bạn chưa đăng nhập',
                ),
          ),
        );
        expect(requestCount, 0);
      });
    }

    test('getOverview parses malformed values gracefully', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'totalOrders': null, 'totalOrderRevenue': 'invalid'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = AdminReportApi(
        apiClient: ApiClient(
          httpClient: client,
          baseUrl: 'http://localhost/api',
        ),
        tokenStorage: TokenStorage(),
      );

      final result = await api.getOverview();
      expect(result.totalOrders, 0);
      expect(result.totalOrderRevenue, 0.0);
    });

    test(
      'getTopProducts calls correct endpoint with limit and parses response',
      () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/api/reports/top-products');
          expect(request.url.queryParameters, {
            'limit': '5',
            'from': '2026-10-01',
            'to': '2026-10-31',
          });
          expect(request.headers['authorization'], 'Bearer admin-token');

          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'productId': '1',
                  'productName': 'Product 1',
                  'totalQuantity': '10',
                  'totalRevenue': 100000,
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final api = AdminReportApi(
          apiClient: ApiClient(
            httpClient: client,
            baseUrl: 'http://localhost/api',
          ),
          tokenStorage: TokenStorage(),
        );

        final result = await api.getTopProducts(
          from: '2026-10-01',
          to: '2026-10-31',
        );
        expect(result.length, 1);
        expect(result.first.productId, '1');
        expect(result.first.productName, 'Product 1');
        expect(result.first.totalQuantity, 10);
        expect(result.first.totalRevenue, 100000.0);
      },
    );

    test(
      'getTopCourts calls correct endpoint with limit and parses response',
      () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/api/reports/top-courts');
          expect(request.url.queryParameters, {
            'limit': '5',
            'from': '2026-10-01',
            'to': '2026-10-31',
          });
          expect(request.headers['authorization'], 'Bearer admin-token');

          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'courtId': 2,
                  'courtName': 'Court 2',
                  'branchName': 'Branch 1',
                  'bookingCount': 5,
                  'totalRevenue': '50000',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final api = AdminReportApi(
          apiClient: ApiClient(
            httpClient: client,
            baseUrl: 'http://localhost/api',
          ),
          tokenStorage: TokenStorage(),
        );

        final result = await api.getTopCourts(
          from: '2026-10-01',
          to: '2026-10-31',
        );
        expect(result.length, 1);
        expect(result.first.courtId, '2');
        expect(result.first.courtName, 'Court 2');
        expect(result.first.branchName, 'Branch 1');
        expect(result.first.bookingCount, 5);
        expect(result.first.totalRevenue, 50000.0);
      },
    );

    test('malformed top-list entries are ignored safely', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              null,
              'invalid',
              {'productId': '1'},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = AdminReportApi(
        apiClient: ApiClient(
          httpClient: client,
          baseUrl: 'http://localhost/api',
        ),
        tokenStorage: TokenStorage(),
      );

      final result = await api.getTopProducts();

      expect(result, hasLength(1));
      expect(result.single.productId, '1');
      expect(result.single.productName, '');
      expect(result.single.totalQuantity, 0);
      expect(result.single.totalRevenue, 0);
    });

    for (final statusCode in [400, 403]) {
      test('propagates backend $statusCode as ApiException', () async {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({'success': false, 'message': 'Backend $statusCode'}),
            statusCode,
            headers: {'content-type': 'application/json'},
          );
        });
        final api = AdminReportApi(
          apiClient: ApiClient(
            httpClient: client,
            baseUrl: 'http://localhost/api',
          ),
          tokenStorage: TokenStorage(),
        );

        await expectLater(
          api.getOverview(),
          throwsA(
            isA<ApiException>()
                .having((error) => error.statusCode, 'statusCode', statusCode)
                .having(
                  (error) => error.message,
                  'message',
                  'Backend $statusCode',
                ),
          ),
        );
      });
    }

    test('handles backend errors gracefully', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': false, 'message': 'Lỗi server'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = AdminReportApi(
        apiClient: ApiClient(
          httpClient: client,
          baseUrl: 'http://localhost/api',
        ),
        tokenStorage: TokenStorage(),
      );

      try {
        await api.getOverview();
        fail('Should throw');
      } catch (e) {
        expect(e, isA<ApiException>());
        expect((e as ApiException).message, 'Lỗi server');
        expect(e.statusCode, 500);
      }
    });
  });
}
