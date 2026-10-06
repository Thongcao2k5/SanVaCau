import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/cart/data/cart_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'clearCart deletes the authenticated cart and parses the result',
    () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/cart');
        expect(request.headers['authorization'], 'Bearer test-token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'cart': {
                'id': '1',
                'customerId': '7',
                'items': <dynamic>[],
                'totalAmount': '0',
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = CartApi(
        apiClient: ApiClient(
          httpClient: client,
          baseUrl: 'http://localhost/api',
        ),
        tokenStorage: TokenStorage(),
      );

      final cart = await api.clearCart();

      expect(cart.id, '1');
      expect(cart.customerId, '7');
      expect(cart.items, isEmpty);
      expect(cart.totalAmount, 0);
    },
  );
}
