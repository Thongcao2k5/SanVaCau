class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    this.brandId,
    this.description,
    this.imageUrl,
    this.brand,
  });

  final String id;
  final String categoryId;
  final String? brandId;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProductCategory category;
  final ProductBrand? brand;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      categoryId: json['categoryId'].toString(),
      brandId: json['brandId']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      isActive: json['isActive'] == true,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
      category: ProductCategory.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      brand: json['brand'] == null
          ? null
          : ProductBrand.fromJson(json['brand'] as Map<String, dynamic>),
    );
  }
}

class ProductCategory {
  const ProductCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
    );
  }
}

class ProductBrand {
  const ProductBrand({required this.id, required this.name});

  final String id;
  final String name;

  factory ProductBrand.fromJson(Map<String, dynamic> json) {
    return ProductBrand(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
    );
  }
}
