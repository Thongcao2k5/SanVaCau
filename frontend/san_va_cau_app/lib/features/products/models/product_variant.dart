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
    final name = json['variantName']?.toString() ?? '';
    final parts = name.replaceAll(' (DEMO)', '').split(' / ');
    final hasPair = parts.length == 2;
    final racket = hasPair && parts.first.startsWith('Trọng lượng ');
    return ProductVariant(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      imageUrl: json['imageUrl']?.toString(),
      stockQuantity: int.tryParse(json['stockQuantity']?.toString() ?? '') ?? 0,
      option1Name:
          json['option1Name']?.toString() ??
          (hasPair
              ? racket
                    ? 'Trọng lượng'
                    : 'Màu sắc'
              : null),
      option1Value:
          json['option1Value']?.toString() ??
          (hasPair ? parts.first.replaceFirst('Trọng lượng ', '') : null),
      option2Name:
          json['option2Name']?.toString() ??
          (hasPair
              ? racket
                    ? 'Cỡ cán'
                    : parts.last.startsWith('Gói ')
                    ? 'Quy cách'
                    : 'Size'
              : null),
      option2Value:
          json['option2Value']?.toString() ??
          (hasPair
              ? parts.last.replaceFirst(
                  RegExp(r'^(Cỡ cán |Size EU |Size )'),
                  '',
                )
              : null),
      isActive: json['isActive'] == true,
    );
  }
}
