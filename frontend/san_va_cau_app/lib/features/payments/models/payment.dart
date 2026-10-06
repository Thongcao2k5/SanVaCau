class Payment {
  const Payment({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.provider,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.transactionRef,
    this.paidAt,
    this.failedAt,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String provider;
  final String amount;
  final String status;
  final String? transactionRef;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? failedAt;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      provider: json['provider']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      status: json['status']?.toString() ?? 'PENDING',
      transactionRef: json['transactionRef']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? ''),
      failedAt: DateTime.tryParse(json['failedAt']?.toString() ?? ''),
    );
  }
}
