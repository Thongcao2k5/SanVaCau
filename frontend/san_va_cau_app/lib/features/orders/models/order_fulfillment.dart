class OrderFulfillment {
  const OrderFulfillment({
    required this.id,
    required this.orderId,
    required this.fulfillmentType,
    required this.status,
    required this.shippingFee,
    this.recipientName,
    this.phone,
    this.addressLine,
    this.ward,
    this.district,
    this.city,
    this.note,
    this.trackingCode,
  });

  final String id;
  final String orderId;
  final String fulfillmentType;
  final String status;
  final String shippingFee;
  final String? recipientName;
  final String? phone;
  final String? addressLine;
  final String? ward;
  final String? district;
  final String? city;
  final String? note;
  final String? trackingCode;

  bool get isDelivery => fulfillmentType == 'DELIVERY';

  String get fullAddress => [
    addressLine,
    ward,
    district,
    city,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');

  factory OrderFulfillment.fromJson(Map<String, dynamic> json) {
    return OrderFulfillment(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      fulfillmentType: json['fulfillmentType']?.toString() ?? 'PICKUP',
      status: json['status']?.toString() ?? 'PENDING',
      shippingFee: json['shippingFee']?.toString() ?? '0',
      recipientName: json['recipientName']?.toString(),
      phone: json['phone']?.toString(),
      addressLine: json['addressLine']?.toString(),
      ward: json['ward']?.toString(),
      district: json['district']?.toString(),
      city: json['city']?.toString(),
      note: json['note']?.toString(),
      trackingCode: json['trackingCode']?.toString(),
    );
  }
}
