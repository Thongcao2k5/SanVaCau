class ReviewUser {
  const ReviewUser({required this.id, required this.fullName});

  final String id;
  final String fullName;

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
    );
  }
}

class ReviewTarget {
  const ReviewTarget({
    required this.type,
    required this.id,
    required this.name,
  });

  final String type;
  final String id;
  final String name;

  factory ReviewTarget.fromJson(Map<String, dynamic> json) {
    return ReviewTarget(
      type: json['type']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.rating,
    this.comment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.target,
  });

  final String id;
  final String userId;
  final String targetType;
  final String targetId;
  final int rating;
  final String? comment;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReviewUser? user;
  final ReviewTarget? target;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      rating: json['rating'] as int? ?? 5,
      comment: json['comment']?.toString(),
      status: json['status']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      user: json['user'] != null
          ? ReviewUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      target: json['target'] != null
          ? ReviewTarget.fromJson(json['target'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ReviewPage {
  const ReviewPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<Review> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory ReviewPage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return ReviewPage(
      items: itemsJson
          .map((item) => Review.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? 20,
      total: pagination['total'] as int? ?? 0,
      totalPages: pagination['totalPages'] as int? ?? 0,
    );
  }
}

class ReviewSummary {
  const ReviewSummary({this.averageRating, required this.totalReviews});

  final double? averageRating;
  final int totalReviews;

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSummary(
      averageRating: json['averageRating'] != null
          ? (json['averageRating'] as num).toDouble()
          : null,
      totalReviews: json['totalReviews'] as int? ?? 0,
    );
  }
}
