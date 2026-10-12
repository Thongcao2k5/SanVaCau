import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/payments/data/vnpay_payment_service.dart';

void main() {
  test('rejects foreign, insecure, and malformed checkout URLs', () async {
    final service = VnpayPaymentService();
    for (final url in [
      'http://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
      'https://sandbox.vnpayment.vn.evil.example/paymentv2/vpcpay.html',
      'https://attacker@sandbox.vnpayment.vn/paymentv2/vpcpay.html',
      'https://sandbox.vnpayment.vn/other',
      'not a URL',
    ]) {
      await expectLater(service.openSandbox(url), throwsFormatException);
    }
  });

  test('uses the installed VNPay response descriptions', () {
    expect(VnpayPaymentService.responseMessage('00'), contains('thành công'));
    expect(VnpayPaymentService.responseMessage('24'), contains('hủy'));
  });
}
