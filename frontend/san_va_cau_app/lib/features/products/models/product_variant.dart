class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.sku,
    required this.variantName,
    required this.price,
    this.imageUrl,
    required this.isActive,
  });

  final String id;
  final String productId;
  final String sku;
  final String variantName;
  final String price;
  final String? imageUrl;
  final bool isActive;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'].toString(),
      productId: json['productId'].toString(),
      sku: json['sku'].toString(),
      variantName: json['variantName']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      imageUrl: json['imageUrl']?.toString(),
      isActive: json['isActive'] == true,
    );
  }
}
