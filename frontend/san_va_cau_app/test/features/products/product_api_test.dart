import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/products/data/product_api.dart';

void main() {
  test('getProducts sends category and brand filters', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/products');
      expect(request.url.queryParameters, {'categoryId': '2', 'brandId': '4'});
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'products': [
              {
                'id': '9',
                'categoryId': '2',
                'brandId': '4',
                'name': 'Yonex Astrox',
                'isActive': true,
                'isFeatured': false,
                'createdAt': '2026-10-01T10:00:00.000Z',
                'updatedAt': '2026-10-01T10:00:00.000Z',
                'category': {'id': '2', 'name': 'Vợt cầu lông'},
                'brand': {'id': '4', 'name': 'Yonex'},
              },
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ProductApi(
      apiClient: ApiClient(httpClient: client, baseUrl: 'http://localhost/api'),
    );

    final products = await api.getProducts(categoryId: '2', brandId: '4');

    expect(products, hasLength(1));
    expect(products.single.category.name, 'Vợt cầu lông');
    expect(products.single.brand?.name, 'Yonex');
  });

  test('loads and flattens category tree plus brands for filters', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/categories') {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'categories': [
                {
                  'id': '1',
                  'name': 'Dụng cụ',
                  'children': [
                    {'id': '2', 'name': 'Vợt cầu lông', 'children': []},
                  ],
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      expect(request.url.path, '/api/brands');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'brands': [
              {'id': '4', 'name': 'Yonex'},
              {'id': '5', 'name': 'Victor'},
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ProductApi(
      apiClient: ApiClient(httpClient: client, baseUrl: 'http://localhost/api'),
    );

    final categoriesFuture = api.getCategories();
    final brandsFuture = api.getBrands();
    final categories = await categoriesFuture;
    final brands = await brandsFuture;
    expect(categories.map((item) => item.name), ['Dụng cụ', 'Vợt cầu lông']);
    expect(brands.map((item) => item.name), ['Yonex', 'Victor']);
  });
}
