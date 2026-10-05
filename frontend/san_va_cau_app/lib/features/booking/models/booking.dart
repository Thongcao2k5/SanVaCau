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
    required this.createdAt,
    required this.slots,
  });

  final String id;
  final BookingCourt court;
  final BookingBranch branch;
  final DateTime bookingDate;
  final String status;
  final String totalAmount;
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime createdAt;
  final List<BookingTimeSlot> slots;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'].toString(),
      court: BookingCourt.fromJson(json['court'] as Map<String, dynamic>),
      branch: BookingBranch.fromJson(json['branch'] as Map<String, dynamic>),
      bookingDate:
          DateTime.tryParse(json['bookingDate'].toString()) ?? DateTime.now(),
      status: json['status']?.toString() ?? '',
      totalAmount: json['totalAmount']?.toString() ?? '0',
      paymentMethod: json['paymentMethod']?.toString(),
      paymentStatus: json['paymentStatus']?.toString(),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      slots:
          (json['slots'] as List<dynamic>?)
              ?.map(
                (item) =>
                    BookingTimeSlot.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
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
