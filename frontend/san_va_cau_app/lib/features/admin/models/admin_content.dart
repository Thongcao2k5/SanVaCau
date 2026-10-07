import '../../home/models/home_data.dart';
import '../../news/models/news_article.dart';

bool isValidBannerSchedule(DateTime? startAt, DateTime? endAt) {
  return startAt == null || endAt == null || startAt.isBefore(endAt);
}

class AdminNewsArticle extends NewsArticle {
  const AdminNewsArticle({
    required super.id,
    required super.title,
    required super.summary,
    required super.content,
    required super.thumbnailUrl,
    required super.publishedAt,
    super.branch,
    required this.status,
    required this.authorName,
  });

  final String status;
  final String authorName;

  factory AdminNewsArticle.fromJson(Map<String, dynamic> json) {
    return AdminNewsArticle(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      branch: json['branch'] != null
          ? NewsBranch.fromJson(json['branch'] as Map<String, dynamic>)
          : null,
      status: json['status']?.toString() ?? 'DRAFT',
      authorName: json['author']?['fullName']?.toString() ?? 'Unknown',
    );
  }
}

class AdminBanner extends HomeBanner {
  const AdminBanner({
    required super.id,
    required super.title,
    required super.imageUrl,
    super.linkUrl,
    super.sortOrder,
    this.startAt,
    this.endAt,
    required this.isActive,
  });

  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;

  factory AdminBanner.fromJson(Map<String, dynamic> json) {
    return AdminBanner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      linkUrl: json['linkUrl']?.toString(),
      sortOrder: json['sortOrder'] as int?,
      startAt: json['startAt'] != null
          ? DateTime.tryParse(json['startAt'].toString())
          : null,
      endAt: json['endAt'] != null
          ? DateTime.tryParse(json['endAt'].toString())
          : null,
      isActive: json['isActive'] == true,
    );
  }
}
