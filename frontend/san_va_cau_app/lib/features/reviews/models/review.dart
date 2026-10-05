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
