class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.branchId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    this.branch,
    this.items = const [],
  });

  final String id;
  final String customerId;
  final String branchId;
  final String status;
  final String totalAmount;
  final DateTime createdAt;
  final OrderBranch? branch;
  final List<OrderItem> items;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      customerId: json['customerId'].toString(),
      branchId: json['branchId'].toString(),
      status: json['status']?.toString() ?? '',
      totalAmount: json['totalAmount']?.toString() ?? '0',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      branch: json['branch'] != null
          ? OrderBranch.fromJson(json['branch'] as Map<String, dynamic>)
          : null,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OrderBranch {
  const OrderBranch({
    required this.id,
    required this.name,
    required this.address,
  });

  final String id;
  final String name;
  final String address;

  factory OrderBranch.fromJson(Map<String, dynamic> json) {
    return OrderBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.productVariantId,
    required this.productName,
    required this.variantName,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
  });

  final String id;
  final String productVariantId;
  final String productName;
  final String variantName;
  final String unitPrice;
  final int quantity;
  final String? imageUrl;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      productVariantId: json['productVariantId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      unitPrice: json['unitPrice']?.toString() ?? '0',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}
