import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/review.dart';

class ReviewApi {
  ReviewApi({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<Map<String, dynamic>> getReviews({
    required String targetType,
    required String targetId,
    int page = 1,
    int limit = 10,
  }) async {
    final path = targetType.toUpperCase() == 'PRODUCT'
        ? '/reviews/products/$targetId'
        : '/reviews/courts/$targetId';

    final response = await _apiClient.get(
      path,
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );

    final data = response['data'] as Map<String, dynamic>;
    final summary = ReviewSummary.fromJson(
      data['summary'] as Map<String, dynamic>,
    );
    final itemsJson = data['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((json) => Review.fromJson(json as Map<String, dynamic>))
        .toList();

    return {'summary': summary, 'items': items};
  }

  Future<Review> createReview({
    required String targetType,
    required String targetId,
    required int rating,
    String? comment,
  }) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Vui lòng đăng nhập để đánh giá',
      );
    }

    final response = await _apiClient.post(
      '/reviews',
      token: token,
      body: {
        'targetType': targetType.toUpperCase(),
        'targetId': targetId,
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return Review.fromJson(data['review'] as Map<String, dynamic>);
  }
}
