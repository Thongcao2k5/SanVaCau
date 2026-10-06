import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/reviews/data/review_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-token'});
  });

  test(
    'getMyReviews sends auth, filters, and parses target metadata',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/reviews/me');
        expect(request.url.queryParameters, {
          'page': '2',
          'limit': '5',
          'targetType': 'PRODUCT',
          'status': 'PUBLISHED',
        });
        expect(request.headers['authorization'], 'Bearer test-token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': '9',
                  'userId': '3',
                  'targetType': 'PRODUCT',
                  'targetId': '7',
                  'target': {
                    'type': 'PRODUCT',
                    'id': '7',
                    'name': 'Yonex Astrox 100 ZZ',
                  },
                  'rating': 5,
                  'comment': 'Rat tot',
                  'status': 'PUBLISHED',
                  'createdAt': '2026-10-01T10:00:00.000Z',
                  'updatedAt': '2026-10-02T10:00:00.000Z',
                },
              ],
              'pagination': {
                'page': 2,
                'limit': 5,
                'total': 8,
                'totalPages': 2,
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ReviewApi(
        apiClient: ApiClient(
          httpClient: client,
          baseUrl: 'http://localhost/api',
        ),
        tokenStorage: TokenStorage(),
      );

      final result = await api.getMyReviews(
        page: 2,
        limit: 5,
        targetType: 'product',
        status: 'published',
      );

      expect(result.items, hasLength(1));
      expect(result.items.single.target?.name, 'Yonex Astrox 100 ZZ');
      expect(result.items.single.target?.type, 'PRODUCT');
      expect(result.page, 2);
      expect(result.limit, 5);
      expect(result.total, 8);
      expect(result.totalPages, 2);
    },
  );

  test(
    'updateReview normalizes the body and parses the updated review',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/reviews/9');
        expect(request.headers['authorization'], 'Bearer test-token');
        expect(jsonDecode(request.body), {'rating': 4, 'comment': 'Da sua'});

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'review': {
                'id': '9',
                'userId': '3',
                'targetType': 'PRODUCT',
                'targetId': '7',
                'rating': 4,
                'comment': 'Da sua',
                'status': 'PUBLISHED',
                'createdAt': '2026-10-01T10:00:00.000Z',
                'updatedAt': '2026-10-03T10:00:00.000Z',
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ReviewApi(
        apiClient: ApiClient(
          httpClient: client,
          baseUrl: 'http://localhost/api',
        ),
        tokenStorage: TokenStorage(),
      );

      final review = await api.updateReview(
        reviewId: '9',
        rating: 4,
        comment: '  Da sua  ',
      );

      expect(review.rating, 4);
      expect(review.comment, 'Da sua');
    },
  );

  test('updateReview sends null to clear a blank comment', () async {
    final client = MockClient((request) async {
      expect(jsonDecode(request.body), {'rating': 3, 'comment': null});
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'review': {
              'id': '9',
              'userId': '3',
              'targetType': 'COURT',
              'targetId': '2',
              'rating': 3,
              'comment': null,
              'status': 'PUBLISHED',
              'createdAt': '2026-10-01T10:00:00.000Z',
              'updatedAt': '2026-10-03T10:00:00.000Z',
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ReviewApi(
      apiClient: ApiClient(httpClient: client, baseUrl: 'http://localhost/api'),
      tokenStorage: TokenStorage(),
    );

    final review = await api.updateReview(
      reviewId: '9',
      rating: 3,
      comment: '   ',
    );

    expect(review.comment, isNull);
  });

  test('personal review methods require an authentication token', () async {
    SharedPreferences.setMockInitialValues({});
    final api = ReviewApi(
      apiClient: ApiClient(
        httpClient: MockClient((_) async => http.Response('{}', 500)),
      ),
      tokenStorage: TokenStorage(),
    );

    await expectLater(
      api.getMyReviews(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    await expectLater(
      api.updateReview(reviewId: '9', rating: 4, comment: 'Test'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });

  test('getMyReviews exposes API errors', () async {
    final api = ReviewApi(
      apiClient: ApiClient(
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'success': false, 'message': 'Server error'}),
            500,
            headers: {'content-type': 'application/json'},
          ),
        ),
        baseUrl: 'http://localhost/api',
      ),
      tokenStorage: TokenStorage(),
    );

    await expectLater(
      api.getMyReviews(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 500)
            .having((error) => error.message, 'message', 'Server error'),
      ),
    );
  });
}
