import '../../products/models/product.dart';

class HomeData {
  const HomeData({
    required this.banners,
    required this.featuredProducts,
    required this.latestNews,
    required this.branches,
  });

  final List<HomeBanner> banners;
  final List<Product> featuredProducts;
  final List<HomeNews> latestNews;
  final List<HomeBranch> branches;

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      banners:
          (json['banners'] as List<dynamic>?)
              ?.map((e) => HomeBanner.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      featuredProducts:
          (json['featuredProducts'] as List<dynamic>?)
              ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      latestNews:
          (json['latestNews'] as List<dynamic>?)
              ?.map((e) => HomeNews.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      branches:
          (json['branches'] as List<dynamic>?)
              ?.map((e) => HomeBranch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkUrl,
    this.sortOrder,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String? linkUrl;
  final int? sortOrder;

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      linkUrl: json['linkUrl']?.toString(),
      sortOrder: json['sortOrder'] as int?,
    );
  }
}

class HomeNewsBranch {
  const HomeNewsBranch({required this.id, required this.name});

  final String id;
  final String name;

  factory HomeNewsBranch.fromJson(Map<String, dynamic> json) {
    return HomeNewsBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class HomeNews {
  const HomeNews({
    required this.id,
    required this.title,
    required this.summary,
    required this.thumbnailUrl,
    required this.publishedAt,
    this.branch,
  });

  final String id;
  final String title;
  final String summary;
  final String thumbnailUrl;
  final DateTime? publishedAt;
  final HomeNewsBranch? branch;

  factory HomeNews.fromJson(Map<String, dynamic> json) {
    return HomeNews(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'].toString())
          : null,
      branch: json['branch'] != null
          ? HomeNewsBranch.fromJson(json['branch'] as Map<String, dynamic>)
          : null,
    );
  }
}

class HomeBranch {
  const HomeBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.openingTime,
    required this.closingTime,
    required this.status,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String openingTime;
  final String closingTime;
  final String status;

  factory HomeBranch.fromJson(Map<String, dynamic> json) {
    return HomeBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      openingTime: json['openingTime']?.toString() ?? '',
      closingTime: json['closingTime']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}
