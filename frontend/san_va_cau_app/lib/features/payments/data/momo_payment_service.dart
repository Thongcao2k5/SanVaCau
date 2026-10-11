import 'package:momo_payment_flutter/momo_payment_flutter.dart';

class MomoPaymentService {
  // URL launching does not require credentials. Only the backend signs requests.
  final MomoPayment _launcher = MomoPayment(
    partnerCode: '',
    accessKey: '',
    secretKey: '',
    isTestMode: true,
  );

  Future<void> openSandbox(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'test-payment.momo.vn' ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Đường dẫn MoMo Sandbox không hợp lệ.');
    }
    await _launcher.openPaymentPage(url);
  }
}
