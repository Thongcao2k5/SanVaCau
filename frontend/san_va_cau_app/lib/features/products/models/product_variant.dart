class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.sku,
    required this.variantName,
    required this.price,
    this.imageUrl,
    this.stockQuantity = 0,
    this.option1Name,
    this.option1Value,
    this.option2Name,
    this.option2Value,
    required this.isActive,
  });

  final String id;
  final String productId;
  final String sku;
  final String variantName;
  final String price;
  final String? imageUrl;
  final int stockQuantity;
  final String? option1Name;
  final String? option1Value;
  final String? option2Name;
  final String? option2Value;
  final bool isActive;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      imageUrl: json['imageUrl']?.toString(),
      stockQuantity: int.tryParse(json['stockQuantity']?.toString() ?? '') ?? 0,
      option1Name: json['option1Name']?.toString(),
      option1Value: json['option1Value']?.toString(),
      option2Name: json['option2Name']?.toString(),
      option2Value: json['option2Value']?.toString(),
      isActive: json['isActive'] == true,
    );
  }
}
