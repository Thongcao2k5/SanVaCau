class SearchResultItem {
  const SearchResultItem({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.metadata,
  });

  final String type;
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final Map<String, dynamic> metadata;

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      type: json['type']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}

class SearchData {
  const SearchData({
    required this.query,
    required this.type,
    required this.items,
    required this.counts,
  });

  final String query;
  final String type;
  final List<SearchResultItem> items;
  final Map<String, int> counts;

  factory SearchData.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final countsMap = json['counts'] as Map<String, dynamic>? ?? {};

    return SearchData(
      query: json['query']?.toString() ?? '',
      type: json['type']?.toString() ?? 'ALL',
      items: itemsList
          .map(
            (item) => SearchResultItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      counts: countsMap.map(
        (key, value) => MapEntry(key.toString(), value is int ? value : 0),
      ),
    );
  }
}
