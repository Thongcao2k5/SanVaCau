class AdminReportOverview {
  const AdminReportOverview({
    required this.totalOrders,
    required this.totalOrderRevenue,
    required this.totalBookings,
    required this.totalBookingRevenue,
    required this.totalPayments,
    required this.totalPaidAmount,
    required this.totalCustomers,
    required this.totalSupportTickets,
    required this.openSupportTickets,
    required this.resolvedSupportTickets,
  });

  final int totalOrders;
  final double totalOrderRevenue;
  final int totalBookings;
  final double totalBookingRevenue;
  final int totalPayments;
  final double totalPaidAmount;
  final int totalCustomers;
  final int totalSupportTickets;
  final int openSupportTickets;
  final int resolvedSupportTickets;

  factory AdminReportOverview.fromJson(Map<String, dynamic> json) {
    return AdminReportOverview(
      totalOrders: _integer(json['totalOrders']),
      totalOrderRevenue: _decimal(json['totalOrderRevenue']),
      totalBookings: _integer(json['totalBookings']),
      totalBookingRevenue: _decimal(json['totalBookingRevenue']),
      totalPayments: _integer(json['totalPayments']),
      totalPaidAmount: _decimal(json['totalPaidAmount']),
      totalCustomers: _integer(json['totalCustomers']),
      totalSupportTickets: _integer(json['totalSupportTickets']),
      openSupportTickets: _integer(json['openSupportTickets']),
      resolvedSupportTickets: _integer(json['resolvedSupportTickets']),
    );
  }
}

class AdminReportTopProduct {
  const AdminReportTopProduct({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  final String productId;
  final String productName;
  final int totalQuantity;
  final double totalRevenue;

  factory AdminReportTopProduct.fromJson(Map<String, dynamic> json) {
    return AdminReportTopProduct(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      totalQuantity: _integer(json['totalQuantity']),
      totalRevenue: _decimal(json['totalRevenue']),
    );
  }
}

class AdminReportTopCourt {
  const AdminReportTopCourt({
    required this.courtId,
    required this.courtName,
    required this.branchName,
    required this.bookingCount,
    required this.totalRevenue,
  });

  final String courtId;
  final String courtName;
  final String branchName;
  final int bookingCount;
  final double totalRevenue;

  factory AdminReportTopCourt.fromJson(Map<String, dynamic> json) {
    return AdminReportTopCourt(
      courtId: json['courtId']?.toString() ?? '',
      courtName: json['courtName']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      bookingCount: _integer(json['bookingCount']),
      totalRevenue: _decimal(json['totalRevenue']),
    );
  }
}

int _integer(Object? value) {
  return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

double _decimal(Object? value) {
  return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
