class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.openingTime,
    required this.closingTime,
    required this.status,
    this.phone,
    this.description,
    this.imageUrl,
    this.isFeatured = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String address;
  final String? phone;
  final String openingTime;
  final String closingTime;
  final String status;
  final String? description;
  final String? imageUrl;
  final bool isFeatured;
  final int sortOrder;

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString(),
      openingTime: json['openingTime']?.toString() ?? '',
      closingTime: json['closingTime']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      isFeatured: json['isFeatured'] == true,
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] as int : 0,
    );
  }
}
