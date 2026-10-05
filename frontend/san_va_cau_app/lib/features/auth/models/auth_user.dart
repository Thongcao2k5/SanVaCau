class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    this.phone,
    this.branchId,
    this.mustChangePassword = false,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String role;
  final String status;
  final String? branchId;
  final bool mustChangePassword;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      branchId: json['branchId']?.toString(),
      mustChangePassword: json['mustChangePassword'] == true,
    );
  }
}
