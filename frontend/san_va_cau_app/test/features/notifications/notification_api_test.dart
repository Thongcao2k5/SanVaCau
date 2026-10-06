import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/notifications/data/notification_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('getUnreadCount returns the authenticated user unread count', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
    final client = MockClient((request) async {
      expect(request.url.path, '/api/notifications/unread-count');
      expect(request.headers['authorization'], 'Bearer test-token');

      return http.Response(
        jsonEncode({
          'success': true,
          'data': {'count': 3},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = NotificationApi(
      apiClient: ApiClient(httpClient: client, baseUrl: 'http://localhost/api'),
      tokenStorage: TokenStorage(),
    );

    expect(await api.getUnreadCount(), 3);
  });

  test('getUnreadCount requires an authentication token', () async {
    SharedPreferences.setMockInitialValues({});
    final api = NotificationApi(
      apiClient: ApiClient(
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      ),
      tokenStorage: TokenStorage(),
    );

    expect(
      api.getUnreadCount(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });
}
