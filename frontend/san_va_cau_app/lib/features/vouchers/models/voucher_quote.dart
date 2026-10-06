class VoucherQuote {
  const VoucherQuote({
    required this.code,
    required this.title,
    required this.discountAmount,
    required this.finalAmount,
  });

  final String code;
  final String title;
  final double discountAmount;
  final double finalAmount;

  factory VoucherQuote.fromJson(Map<String, dynamic> json) {
    final voucher = json['voucher'] as Map<String, dynamic>? ?? const {};
    return VoucherQuote(
      code: voucher['code']?.toString() ?? '',
      title: voucher['title']?.toString() ?? '',
      discountAmount:
          double.tryParse(json['discountAmount']?.toString() ?? '') ?? 0,
      finalAmount: double.tryParse(json['finalAmount']?.toString() ?? '') ?? 0,
    );
  }
}
