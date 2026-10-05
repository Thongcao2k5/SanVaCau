class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.thumbnailUrl,
    required this.publishedAt,
    this.branch,
  });

  final String id;
  final String title;
  final String summary;
  final String content;
  final String thumbnailUrl;
  final DateTime? publishedAt;
  final NewsBranch? branch;

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
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
    );
  }
}

class NewsBranch {
  const NewsBranch({required this.id, required this.name});

  final String id;
  final String name;

  factory NewsBranch.fromJson(Map<String, dynamic> json) {
    return NewsBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
