class AdminDashboard {
  const AdminDashboard({
    required this.role,
    required this.branchId,
    required this.date,
    required this.bookings,
    required this.orders,
    required this.inventory,
    required this.courts,
    required this.latestBookings,
    required this.latestOrders,
  });

  final String role;
  final String? branchId;
  final String date;
  final AdminBookingSummary bookings;
  final AdminOrderSummary orders;
  final AdminInventorySummary inventory;
  final AdminCourtSummary courts;
  final List<AdminRecentBooking> latestBookings;
  final List<AdminRecentOrder> latestOrders;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    final scope = _map(json['scope']);
    return AdminDashboard(
      role: scope['role']?.toString() ?? '',
      branchId: scope['branchId']?.toString(),
      date: json['date']?.toString() ?? '',
      bookings: AdminBookingSummary.fromJson(_map(json['bookings'])),
      orders: AdminOrderSummary.fromJson(_map(json['orders'])),
      inventory: AdminInventorySummary.fromJson(_map(json['inventory'])),
      courts: AdminCourtSummary.fromJson(_map(json['courts'])),
      latestBookings: _list(json['latestBookings'])
          .map((item) => AdminRecentBooking.fromJson(_map(item)))
          .toList(),
      latestOrders: _list(json['latestOrders'])
          .map((item) => AdminRecentOrder.fromJson(_map(item)))
          .toList(),
    );
  }
}

class AdminBookingSummary {
  const AdminBookingSummary({
    required this.total,
    required this.booked,
    required this.checkedIn,
    required this.completed,
    required this.cancelled,
  });

  final int total;
  final int booked;
  final int checkedIn;
  final int completed;
  final int cancelled;

  factory AdminBookingSummary.fromJson(Map<String, dynamic> json) {
    return AdminBookingSummary(
      total: _integer(json['total']),
      booked: _integer(json['booked']),
      checkedIn: _integer(json['checkedIn']),
      completed: _integer(json['completed']),
      cancelled: _integer(json['cancelled']),
    );
  }
}

class AdminOrderSummary {
  const AdminOrderSummary({
    required this.total,
    required this.pending,
    required this.readyForPickup,
    required this.completed,
    required this.cancelled,
    required this.revenueCompleted,
  });

  final int total;
  final int pending;
  final int readyForPickup;
  final int completed;
  final int cancelled;
  final double revenueCompleted;

  factory AdminOrderSummary.fromJson(Map<String, dynamic> json) {
    return AdminOrderSummary(
      total: _integer(json['total']),
      pending: _integer(json['pending']),
      readyForPickup: _integer(json['readyForPickup']),
      completed: _integer(json['completed']),
      cancelled: _integer(json['cancelled']),
      revenueCompleted: _decimal(json['revenueCompleted']),
    );
  }
}

class AdminInventorySummary {
  const AdminInventorySummary({
    required this.lowStockCount,
    required this.lowStockItems,
  });

  final int lowStockCount;
  final List<AdminLowStockItem> lowStockItems;

  factory AdminInventorySummary.fromJson(Map<String, dynamic> json) {
    return AdminInventorySummary(
      lowStockCount: _integer(json['lowStockCount']),
      lowStockItems: _list(json['lowStockItems'])
          .map((item) => AdminLowStockItem.fromJson(_map(item)))
          .toList(),
    );
  }
}

class AdminLowStockItem {
  const AdminLowStockItem({
    required this.id,
    required this.branchName,
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.quantity,
  });

  final String id;
  final String branchName;
  final String productName;
  final String variantName;
  final String sku;
  final int quantity;

  factory AdminLowStockItem.fromJson(Map<String, dynamic> json) {
    return AdminLowStockItem(
      id: json['inventoryId']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      variantName: json['variantName']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      quantity: _integer(json['quantity']),
    );
  }
}

class AdminCourtSummary {
  const AdminCourtSummary({
    required this.active,
    required this.maintenance,
    required this.inactive,
  });

  final int active;
  final int maintenance;
  final int inactive;

  factory AdminCourtSummary.fromJson(Map<String, dynamic> json) {
    return AdminCourtSummary(
      active: _integer(json['active']),
      maintenance: _integer(json['maintenance']),
      inactive: _integer(json['inactive']),
    );
  }
}

class AdminRecentBooking {
  const AdminRecentBooking({
    required this.id,
    required this.date,
    required this.status,
    required this.totalAmount,
    required this.courtName,
    required this.branchName,
    required this.customerName,
  });

  final String id;
  final String date;
  final String status;
  final double totalAmount;
  final String courtName;
  final String branchName;
  final String customerName;

  factory AdminRecentBooking.fromJson(Map<String, dynamic> json) {
    return AdminRecentBooking(
      id: json['id']?.toString() ?? '',
      date: json['bookingDate']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalAmount: _decimal(json['totalAmount']),
      courtName: _map(json['court'])['name']?.toString() ?? '',
      branchName: _map(json['branch'])['name']?.toString() ?? '',
      customerName: _map(json['customer'])['fullName']?.toString() ?? '',
    );
  }
}

class AdminRecentOrder {
  const AdminRecentOrder({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.branchName,
    required this.customerName,
  });

  final String id;
  final String status;
  final double totalAmount;
  final DateTime? createdAt;
  final String branchName;
  final String customerName;

  factory AdminRecentOrder.fromJson(Map<String, dynamic> json) {
    return AdminRecentOrder(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalAmount: _decimal(json['totalAmount']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      branchName: _map(json['branch'])['name']?.toString() ?? '',
      customerName: _map(json['customer'])['fullName']?.toString() ?? '',
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

List<dynamic> _list(Object? value) {
  return value is List<dynamic> ? value : <dynamic>[];
}

int _integer(Object? value) {
  return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

double _decimal(Object? value) {
  return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
