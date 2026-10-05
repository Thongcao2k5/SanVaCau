class Court {
  const Court({
    required this.id,
    required this.branchId,
    required this.name,
    required this.status,
    this.branchName,
    this.branchAddress,
    this.description,
  });

  final String id;
  final String branchId;
  final String name;
  final String? branchName;
  final String? branchAddress;
  final String? description;
  final String status;

  factory Court.fromJson(Map<String, dynamic> json) {
    final branch = json['branch'] as Map<String, dynamic>?;

    return Court(
      id: json['id']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      branchName: branch?['name']?.toString(),
      branchAddress: branch?['address']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? '',
    );
  }
}

class BookingSlot {
  const BookingSlot({
    required this.timeSlotId,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.isBooked,
  });

  final String timeSlotId;
  final String startTime;
  final String endTime;
  final double price;
  final bool isBooked;

  factory BookingSlot.fromJson(Map<String, dynamic> json) {
    return BookingSlot(
      timeSlotId: json['timeSlotId']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      isBooked: json['isBooked'] == true,
    );
  }
}

class CourtPrice {
  const CourtPrice({
    required this.id,
    required this.timeSlotId,
    required this.price,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  final String id;
  final String timeSlotId;
  final double price;
  final String startTime;
  final String endTime;
  final bool isActive;

  factory CourtPrice.fromJson(Map<String, dynamic> json) {
    final timeSlot = json['timeSlot'] as Map<String, dynamic>? ?? {};
    return CourtPrice(
      id: json['id']?.toString() ?? '',
      timeSlotId: json['timeSlotId']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0,
      startTime: timeSlot['startTime']?.toString() ?? '',
      endTime: timeSlot['endTime']?.toString() ?? '',
      isActive: timeSlot['isActive'] == true,
    );
  }
}
