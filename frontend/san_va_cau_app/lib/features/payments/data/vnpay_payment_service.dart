import 'package:url_launcher/url_launcher.dart';
import 'package:vnpay_payment_flutter/vnpay_payment_flutter.dart';

class VnpayPaymentService {
  // Signing and verification use server credentials; the app never contains Hash Secret.
  static String responseMessage(String code) =>
      VNPayResponseCode.getByCode(code).message;

  Future<void> openSandbox(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != Uri.parse(VNPAYPayment.sandboxPaymentUrl).host ||
        uri.path != '/paymentv2/vpcpay.html' ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Đường dẫn VNPay Sandbox không hợp lệ.');
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Không mở được trang VNPay Sandbox.');
    }
  }
}
