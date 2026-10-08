import '../../../core/network/api_client.dart';
import '../models/news_article.dart';

class NewsApi {
  NewsApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  // Retained so this data source can switch back to the backend after UI testing.
  // ignore: unused_field
  final ApiClient _apiClient;

  Future<List<NewsArticle>> getNews() async {
    return [
      NewsArticle(
        id: 'n1',
        title: 'Khai trương chi nhánh Sân Và Cầu Quận 1',
        summary:
            'Không gian sân mới, hệ thống ánh sáng và thảm thi đấu đạt chuẩn.',
        content: 'Chi nhánh mới chính thức hoạt động với nhiều khung giờ đặt sân, khu vực nghỉ và dịch vụ căng vợt dành cho người chơi cầu lông.',
        thumbnailUrl: 'assets/demo/banner-court.jpg',
        publishedAt: DateTime.now(),
      ),
      NewsArticle(
        id: 'n2',
        title: '5 dấu hiệu bạn nên căng lại dây vợt',
        summary: 'Kiểm tra dây vợt định kỳ để giữ cảm giác đánh ổn định.',
        content: 'Dây bị xô, âm thanh khi đánh thay đổi hoặc lực cầu giảm là những dấu hiệu phổ biến. Hãy chọn mức căng phù hợp với trình độ và tình trạng khung vợt.',
        thumbnailUrl: 'assets/demo/news-stringing.png',
        publishedAt: DateTime.now(),
      ),
    ];
  }

  Future<NewsArticle> getNewsById(String id) async {
    final newsList = await getNews();
    return newsList.firstWhere((n) => n.id == id, orElse: () => newsList.first);
  }
}
