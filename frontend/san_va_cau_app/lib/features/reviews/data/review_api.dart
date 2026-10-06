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
    final token = await _readRequiredToken();

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

  Future<ReviewPage> getMyReviews({
    int page = 1,
    int limit = 20,
    String? targetType,
    String? status,
  }) async {
    final token = await _readRequiredToken();
    final normalizedTargetType = targetType?.trim().toUpperCase();
    final normalizedStatus = status?.trim().toUpperCase();
    final response = await _apiClient.get(
      '/reviews/me',
      token: token,
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (normalizedTargetType != null && normalizedTargetType.isNotEmpty)
          'targetType': normalizedTargetType,
        if (normalizedStatus != null && normalizedStatus.isNotEmpty)
          'status': normalizedStatus,
      },
    );

    return ReviewPage.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Review> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) async {
    final token = await _readRequiredToken();
    final normalizedComment = comment?.trim();
    final response = await _apiClient.patch(
      '/reviews/$reviewId',
      token: token,
      body: {
        'rating': rating,
        'comment': normalizedComment == null || normalizedComment.isEmpty
            ? null
            : normalizedComment,
      },
    );

    final data = response['data'] as Map<String, dynamic>;
    return Review.fromJson(data['review'] as Map<String, dynamic>);
  }

  Future<String> _readRequiredToken() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'Vui lòng đăng nhập để đánh giá',
      );
    }
    return token;
  }
}
