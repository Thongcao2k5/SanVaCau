class Booking {
  const Booking({
    required this.id,
    required this.court,
    required this.branch,
    required this.bookingDate,
    required this.status,
    required this.totalAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.createdAt,
    this.checkedInAt,
    this.completedAt,
    this.cancelledAt,
    this.customer,
    required this.slots,
  });

  final String id;
  final BookingCourt court;
  final BookingBranch branch;
  final DateTime? bookingDate;
  final String status;
  final String totalAmount;
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime? createdAt;
  final DateTime? checkedInAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final BookingCustomer? customer;
  final List<BookingTimeSlot> slots;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? '',
      court: BookingCourt.fromJson(_map(json['court'])),
      branch: BookingBranch.fromJson(_map(json['branch'])),
      bookingDate: json['bookingDate'] != null
          ? DateTime.tryParse(json['bookingDate'].toString())
          : null,
      status: json['status']?.toString() ?? '',
      totalAmount: json['totalAmount']?.toString() ?? '0',
      paymentMethod: json['paymentMethod']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.tryParse(json['checkedInAt'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
      customer: json['customer'] is Map<String, dynamic>
          ? BookingCustomer.fromJson(_map(json['customer']))
          : null,
      slots:
          (json['slots'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(BookingTimeSlot.fromJson)
              .toList() ??
          [],
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

class BookingCustomer {
  const BookingCustomer({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  final String id;
  final String fullName;
  final String phone;

  factory BookingCustomer.fromJson(Map<String, dynamic> json) {
    return BookingCustomer(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class BookingCourt {
  const BookingCourt({required this.id, required this.name});

  final String id;
  final String name;

  factory BookingCourt.fromJson(Map<String, dynamic> json) {
    return BookingCourt(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class BookingBranch {
  const BookingBranch({required this.id, required this.name});

  final String id;
  final String name;

  factory BookingBranch.fromJson(Map<String, dynamic> json) {
    return BookingBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class BookingTimeSlot {
  const BookingTimeSlot({
    required this.id,
    required this.timeSlotId,
    required this.startTime,
    required this.endTime,
    required this.priceAtBooking,
  });

  final String id;
  final String timeSlotId;
  final String startTime;
  final String endTime;
  final String priceAtBooking;

  factory BookingTimeSlot.fromJson(Map<String, dynamic> json) {
    return BookingTimeSlot(
      id: json['id']?.toString() ?? '',
      timeSlotId: json['timeSlotId']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      priceAtBooking: json['priceAtBooking']?.toString() ?? '0',
    );
  }
}
