import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/news/data/news_api.dart';
import 'package:san_va_cau_app/features/racket_services/data/racket_service_api.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.responses);

  final Map<String, Map<String, dynamic>> responses;
  final List<String> requestedPaths = [];
  final List<Map<String, String>?> requestedQueries = [];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
    Map<String, String>? queryParameters,
  }) async {
    requestedPaths.add(path);
    requestedQueries.add(queryParameters);
    return responses[path] ?? <String, dynamic>{};
  }
}

void main() {
  test('news API loads published articles from backend', () async {
    final client = _FakeApiClient({
      '/news': {
        'data': {
          'news': [
            {
              'id': '7',
              'title': 'Giải cầu lông cuối tuần',
              'summary': 'Thông tin giải đấu',
              'content': 'Nội dung',
              'thumbnailUrl': '/uploads/news.jpg',
              'publishedAt': '2026-10-11T00:00:00.000Z',
            },
          ],
        },
      },
    });

    final articles = await NewsApi(apiClient: client).getNews();

    expect(client.requestedPaths, ['/news']);
    expect(client.requestedQueries.single, {
      'status': 'PUBLISHED',
      'limit': '50',
    });
    expect(articles.single.id, '7');
    expect(articles.single.title, 'Giải cầu lông cuối tuần');
  });

  test('news detail API loads the requested article from backend', () async {
    final client = _FakeApiClient({
      '/news/7': {
        'data': {
          'news': {
            'id': '7',
            'title': 'Giải cầu lông cuối tuần',
            'summary': 'Thông tin giải đấu',
            'content': 'Nội dung',
            'thumbnailUrl': '',
            'publishedAt': '2026-10-11T00:00:00.000Z',
          },
        },
      },
    });

    final article = await NewsApi(apiClient: client).getNewsById('7');

    expect(client.requestedPaths, ['/news/7']);
    expect(article.id, '7');
  });

  test('racket services API loads services for the selected branch', () async {
    final client = _FakeApiClient({
      '/branches/2/services': {
        'data': {
          'services': [
            {
              'id': '9',
              'branchId': '2',
              'serviceId': '4',
              'referencePrice': '120000',
              'estimatedDuration': '30 phút',
              'service': {'id': '4', 'name': 'Căng vợt'},
            },
          ],
        },
      },
    });

    final services = await RacketServiceApi(apiClient: client)
        .getAvailableServices('2');

    expect(client.requestedPaths, ['/branches/2/services']);
    expect(services.single.service.name, 'Căng vợt');
    expect(services.single.referencePrice, 120000);
  });
}
