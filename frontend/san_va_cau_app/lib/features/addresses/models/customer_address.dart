class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.isDefault,
    this.ward,
    this.district,
    this.city,
    this.note,
  });

  final String id;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String? ward;
  final String? district;
  final String? city;
  final String? note;
  final bool isDefault;

  String get fullAddress => [
    addressLine,
    ward,
    district,
    city,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id']?.toString() ?? '',
      recipientName: json['recipientName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine: json['addressLine']?.toString() ?? '',
      ward: json['ward']?.toString(),
      district: json['district']?.toString(),
      city: json['city']?.toString(),
      note: json['note']?.toString(),
      isDefault: json['isDefault'] == true,
    );
  }
}
