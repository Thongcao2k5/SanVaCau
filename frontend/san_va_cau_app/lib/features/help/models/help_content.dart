class FaqItem {
  const FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  final String id;
  final String category;
  final String question;
  final String answer;

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Khác',
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
    );
  }
}

class StaticPageSummary {
  const StaticPageSummary({
    required this.slug,
    required this.title,
    required this.type,
    this.summary,
  });

  final String slug;
  final String title;
  final String type;
  final String? summary;

  factory StaticPageSummary.fromJson(Map<String, dynamic> json) {
    return StaticPageSummary(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'OTHER',
      summary: json['summary']?.toString(),
    );
  }
}

class StaticPageDetail {
  const StaticPageDetail({
    required this.slug,
    required this.title,
    required this.content,
    required this.type,
    this.summary,
  });

  final String slug;
  final String title;
  final String content;
  final String type;
  final String? summary;

  factory StaticPageDetail.fromJson(Map<String, dynamic> json) {
    return StaticPageDetail(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'OTHER',
      summary: json['summary']?.toString(),
    );
  }
}

class HelpContent {
  const HelpContent({required this.faqs, required this.pages});

  final List<FaqItem> faqs;
  final List<StaticPageSummary> pages;
}
