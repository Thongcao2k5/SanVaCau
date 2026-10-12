class AdminTimeSlot {
  const AdminTimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String startTime;
  final String endTime;
  final int sortOrder;
  final bool isActive;

  factory AdminTimeSlot.fromJson(Map<String, dynamic> json) {
    return AdminTimeSlot(
      id: json['id']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
      isActive: json['isActive'] == true,
    );
  }
}
