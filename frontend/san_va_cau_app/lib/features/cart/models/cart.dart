class Cart {
  const Cart({
    required this.id,
    required this.customerId,
    required this.items,
    required this.totalAmount,
  });

  final String id;
  final String customerId;
  final List<CartItem> items;
  final double totalAmount;

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: double.tryParse(json['totalAmount']?.toString() ?? '') ?? 0,
    );
  }
}

class CartItem {
  const CartItem({
    required this.id,
    required this.productVariantId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.variant,
  });

  final String id;
  final String productVariantId;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final CartVariant variant;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      productVariantId: json['productVariantId']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      unitPrice: double.tryParse(json['unitPrice']?.toString() ?? '') ?? 0,
      lineTotal: double.tryParse(json['lineTotal']?.toString() ?? '') ?? 0,
      variant: CartVariant.fromJson(json['variant'] as Map<String, dynamic>),
    );
  }
}

class CartVariant {
  const CartVariant({
    required this.id,
    required this.sku,
    required this.variantName,
    required this.price,
    required this.product,
    this.imageUrl,
  });

  final String id;
  final String sku;
  final String variantName;
  final double price;
  final String? imageUrl;
  final CartProduct product;

  factory CartVariant.fromJson(Map<String, dynamic> json) {
    return CartVariant(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      imageUrl: json['imageUrl']?.toString(),
      product: CartProduct.fromJson(json['product'] as Map<String, dynamic>),
    );
  }
}

class CartProduct {
  const CartProduct({required this.id, required this.name, this.imageUrl});

  final String id;
  final String name;
  final String? imageUrl;

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}
