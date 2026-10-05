class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.targetImageUrl,
    required this.isActive,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String targetName;
  final String targetImageUrl;
  final bool isActive;

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    final target = json['target'] as Map<String, dynamic>? ?? {};

    return FavoriteItem(
      id: json['id']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      targetName: target['name']?.toString() ?? '',
      targetImageUrl: target['imageUrl']?.toString() ?? '',
      isActive: target['isActive'] == true,
    );
  }
}
