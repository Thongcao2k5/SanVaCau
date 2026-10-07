class AdminInventory {
  const AdminInventory({
    required this.id,
    required this.branchId,
    required this.productVariantId,
    required this.quantity,
    this.updatedAt,
    this.branch,
    this.productVariant,
  });

  final String id;
  final String branchId;
  final String productVariantId;
  final int quantity;
  final DateTime? updatedAt;
  final AdminInventoryBranch? branch;
  final AdminInventoryVariant? productVariant;

  factory AdminInventory.fromJson(Map<String, dynamic> json) {
    return AdminInventory(
      id: json['id']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      productVariantId: json['productVariantId']?.toString() ?? '',
      quantity: json['quantity'] is num
          ? (json['quantity'] as num).toInt()
          : int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      branch: json['branch'] != null && json['branch'] is Map<String, dynamic>
          ? AdminInventoryBranch.fromJson(
              json['branch'] as Map<String, dynamic>,
            )
          : null,
      productVariant:
          json['productVariant'] != null &&
              json['productVariant'] is Map<String, dynamic>
          ? AdminInventoryVariant.fromJson(
              json['productVariant'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class AdminInventoryBranch {
  const AdminInventoryBranch({required this.id, required this.name});

  final String id;
  final String name;

  factory AdminInventoryBranch.fromJson(Map<String, dynamic> json) {
    return AdminInventoryBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class AdminInventoryVariant {
  const AdminInventoryVariant({
    required this.id,
    required this.sku,
    required this.variantName,
    this.product,
  });

  final String id;
  final String sku;
  final String variantName;
  final AdminInventoryProduct? product;

  factory AdminInventoryVariant.fromJson(Map<String, dynamic> json) {
    return AdminInventoryVariant(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      product:
          json['product'] != null && json['product'] is Map<String, dynamic>
          ? AdminInventoryProduct.fromJson(
              json['product'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class AdminInventoryProduct {
  const AdminInventoryProduct({required this.id, required this.name});

  final String id;
  final String name;

  factory AdminInventoryProduct.fromJson(Map<String, dynamic> json) {
    return AdminInventoryProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
