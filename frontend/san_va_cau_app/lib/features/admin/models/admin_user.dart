class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.role,
    required this.status,
    this.branchId,
    required this.mustChangePassword,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String status;
  final String? branchId;
  final bool mustChangePassword;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      branchId: json['branchId']?.toString(),
      mustChangePassword: json['mustChangePassword'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
