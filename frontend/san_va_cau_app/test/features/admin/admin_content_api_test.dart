import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/storage/token_storage.dart';
import 'package:san_va_cau_app/features/admin/data/admin_content_api.dart';

class _FakeTokenStorage extends TokenStorage {
  _FakeTokenStorage(this.token);

  final String? token;

  @override
  Future<String?> readToken() async => token;
}

AdminContentApi _api(MockClient client, {String? token = 'test-token'}) {
  return AdminContentApi(
    client: ApiClient(httpClient: client, baseUrl: 'http://localhost:3000/api'),
    tokenStorage: _FakeTokenStorage(token),
  );
}

http.Response _jsonResponse(
  Map<String, dynamic> body, {
  int statusCode = 200,
}) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  statusCode,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _newsJson({String status = 'DRAFT'}) => {
  'id': '1',
  'title': 'Tin mới',
  'summary': null,
  'content': 'Nội dung',
  'thumbnailUrl': null,
  'status': status,
  'publishedAt': null,
  'author': {'id': '7', 'fullName': 'Admin'},
  'branch': null,
};

Map<String, dynamic> _bannerJson({bool isActive = true}) => {
  'id': '2',
  'title': null,
  'imageUrl': 'https://example.com/banner.jpg',
  'linkUrl': null,
  'sortOrder': 3,
  'startAt': null,
  'endAt': null,
  'isActive': isActive,
};

void main() {
  group('AdminContentApi', () {
    test(
      'getNews builds the real URL, sends token, and parses response',
      () async {
        final api = _api(
          MockClient((request) async {
            expect(request.method, 'GET');
            expect(request.url.path, '/api/news');
            expect(request.url.queryParameters, {
              'status': 'DRAFT',
              'limit': '20',
            });
            expect(request.headers['authorization'], 'Bearer test-token');
            return _jsonResponse({
              'success': true,
              'data': {
                'news': [_newsJson()],
              },
            });
          }),
        );

        final result = await api.getNews(status: 'DRAFT', limit: 20);

        expect(result, hasLength(1));
        expect(result.single.title, 'Tin mới');
        expect(result.single.status, 'DRAFT');
        expect(result.single.authorName, 'Admin');
      },
    );

    test('createNews sends the exact backend body', () async {
      final api = _api(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/news');
          expect(request.headers['authorization'], 'Bearer test-token');
          expect(jsonDecode(request.body), {
            'title': 'Tiêu đề',
            'content': 'Nội dung',
            'summary': null,
            'thumbnailUrl': 'https://example.com/news.jpg',
            'branchId': null,
          });
          return _jsonResponse({
            'success': true,
            'data': {'news': _newsJson()},
          }, statusCode: 201);
        }),
      );

      await api.createNews(
        title: 'Tiêu đề',
        content: 'Nội dung',
        thumbnailUrl: 'https://example.com/news.jpg',
      );
    });

    test(
      'updateNews sends explicit nulls so optional fields can be cleared',
      () async {
        final api = _api(
          MockClient((request) async {
            expect(request.method, 'PATCH');
            expect(request.url.path, '/api/news/9');
            expect(jsonDecode(request.body), {
              'title': 'Tiêu đề mới',
              'content': 'Nội dung mới',
              'summary': null,
              'thumbnailUrl': null,
              'branchId': null,
            });
            return _jsonResponse({
              'success': true,
              'data': {'news': _newsJson()},
            });
          }),
        );

        await api.updateNews(
          id: '9',
          title: 'Tiêu đề mới',
          content: 'Nội dung mới',
        );
      },
    );

    test('publish and archive use the exact endpoints', () async {
      final paths = <String>[];
      final api = _api(
        MockClient((request) async {
          paths.add(request.url.path);
          expect(request.method, 'PATCH');
          expect(request.headers['authorization'], 'Bearer test-token');
          return _jsonResponse({
            'success': true,
            'data': {'news': _newsJson()},
          });
        }),
      );

      await api.publishNews('3');
      await api.archiveNews('4');

      expect(paths, ['/api/news/3/publish', '/api/news/4/archive']);
    });

    test('getBanners is public and parses nullable schedule fields', () async {
      final api = _api(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/banners');
          expect(request.headers.containsKey('authorization'), isFalse);
          return _jsonResponse({
            'success': true,
            'data': {
              'banners': [_bannerJson()],
            },
          });
        }),
      );

      final result = await api.getBanners();

      expect(result, hasLength(1));
      expect(result.single.sortOrder, 3);
      expect(result.single.startAt, isNull);
      expect(result.single.isActive, isTrue);
    });

    test('createBanner sends the exact backend body', () async {
      final startAt = DateTime.parse('2026-10-07T00:00:00.000');
      final endAt = DateTime.parse('2026-10-08T00:00:00.000');
      final api = _api(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/banners');
          expect(jsonDecode(request.body), {
            'title': null,
            'imageUrl': 'https://example.com/banner.jpg',
            'linkUrl': null,
            'sortOrder': 1,
            'startAt': startAt.toIso8601String(),
            'endAt': endAt.toIso8601String(),
          });
          return _jsonResponse({
            'success': true,
            'data': {'banner': _bannerJson()},
          }, statusCode: 201);
        }),
      );

      await api.createBanner(
        imageUrl: 'https://example.com/banner.jpg',
        sortOrder: 1,
        startAt: startAt,
        endAt: endAt,
      );
    });

    test(
      'updateBanner sends explicit nulls and inactivate uses exact path',
      () async {
        var call = 0;
        final api = _api(
          MockClient((request) async {
            call++;
            expect(request.method, 'PATCH');
            if (call == 1) {
              expect(request.url.path, '/api/banners/2');
              expect(jsonDecode(request.body), {
                'title': null,
                'imageUrl': 'https://example.com/new.jpg',
                'linkUrl': null,
                'sortOrder': 4,
                'startAt': null,
                'endAt': null,
              });
            } else {
              expect(request.url.path, '/api/banners/2/inactivate');
            }
            return _jsonResponse({
              'success': true,
              'data': {'banner': _bannerJson(isActive: call == 1)},
            });
          }),
        );

        await api.updateBanner(
          id: '2',
          title: null,
          imageUrl: 'https://example.com/new.jpg',
          linkUrl: null,
          sortOrder: 4,
          startAt: null,
          endAt: null,
        );
        await api.inactivateBanner('2');

        expect(call, 2);
      },
    );

    test(
      'sendNotification sends one-recipient body and parses response',
      () async {
        final api = _api(
          MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.path, '/api/notifications/admin');
            expect(request.headers['authorization'], 'Bearer test-token');
            expect(jsonDecode(request.body), {
              'userId': '99',
              'type': 'SYSTEM',
              'title': 'Thông báo',
              'message': 'Nội dung',
            });
            return _jsonResponse({
              'success': true,
              'data': {
                'notification': {
                  'id': '5',
                  'userId': '99',
                  'type': 'SYSTEM',
                  'title': 'Thông báo',
                  'message': 'Nội dung',
                  'data': null,
                  'isRead': false,
                  'readAt': null,
                  'createdAt': '2026-10-06T00:00:00.000Z',
                },
              },
            }, statusCode: 201);
          }),
        );

        final result = await api.sendNotification(
          userId: '99',
          type: 'SYSTEM',
          title: 'Thông báo',
          message: 'Nội dung',
        );

        expect(result.id, '5');
        expect(result.isRead, isFalse);
      },
    );

    for (final token in <String?>[null, '']) {
      test('missing token "$token" fails before an HTTP request', () async {
        var requestCount = 0;
        final api = _api(
          MockClient((request) async {
            requestCount++;
            return _jsonResponse({'success': true});
          }),
          token: token,
        );

        await expectLater(
          api.getNews(status: 'DRAFT'),
          throwsA(
            isA<ApiException>()
                .having((error) => error.statusCode, 'statusCode', 401)
                .having(
                  (error) => error.message,
                  'message',
                  'Không tìm thấy phiên đăng nhập. Vui lòng đăng nhập lại.',
                ),
          ),
        );
        expect(requestCount, 0);
      });
    }

    for (final statusCode in <int>[403, 404, 409]) {
      test('propagates $statusCode as ApiException', () async {
        final api = _api(
          MockClient((request) async {
            return _jsonResponse({
              'success': false,
              'message': 'Backend $statusCode',
            }, statusCode: statusCode);
          }),
        );

        await expectLater(
          api.publishNews('1'),
          throwsA(
            isA<ApiException>().having(
              (error) => error.statusCode,
              'statusCode',
              statusCode,
            ),
          ),
        );
      });
    }
  });
}
