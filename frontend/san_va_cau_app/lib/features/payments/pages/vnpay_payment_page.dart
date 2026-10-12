import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/vnpay_payment_service.dart';
import '../data/payment_api.dart';
import '../models/payment.dart';

class VnpayPaymentPage extends StatefulWidget {
  const VnpayPaymentPage({required this.payment, super.key});
  final Payment payment;
  @override
  State<VnpayPaymentPage> createState() => _VnpayPaymentPageState();
}

class _VnpayPaymentPageState extends State<VnpayPaymentPage>
    with WidgetsBindingObserver {
  final _api = PaymentApi();
  final _vnpay = VnpayPaymentService();
  late Payment _payment;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _payment = widget.payment;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _check();
  }

  Future<void> _open() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_payment.checkoutUrl == null || _payment.status == 'FAILED') {
        _payment = await _api.createPayment(
          targetType: _payment.targetType,
          targetId: _payment.targetId,
          provider: 'VNPAY_SANDBOX',
        );
      }
      if (_payment.status == 'PAID') {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      await _vnpay.openSandbox(_payment.checkoutUrl ?? '');
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không mở được trang VNPay Sandbox. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payment = await _api.checkVnpay(_payment.id);
      if (!mounted) return;
      setState(() => _payment = payment);
      if (payment.status == 'PAID') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'VNPay Sandbox: ${VnpayPaymentService.responseMessage('00')}',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không kiểm tra được giao dịch. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = (num.tryParse(_payment.amount) ?? 0)
        .round()
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return Scaffold(
      appBar: AppBar(title: const Text('VNPay Sandbox')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Color(0xFF005BAA),
            ),
            const SizedBox(height: 20),
            Text(
              '$amount đ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Giao dịch ${_payment.transactionRef ?? _payment.id}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Môi trường thử nghiệm VNPay Sandbox. Dùng thẻ hoặc tài khoản ngân hàng kiểm thử VNPay.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              _payment.status == 'FAILED' ? 'Thanh toán thất bại hoặc đã hủy.' : 'Chờ VNPay xác nhận. Nếu vừa thanh toán, hãy kiểm tra lại sau vài giây.',
              textAlign: TextAlign.center,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 20),
            if (_payment.status != 'PAID')
              FilledButton.icon(
                onPressed: _busy ? null : _open,
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  _payment.status == 'FAILED'
                      ? 'Thử lại thanh toán'
                      : 'Mở VNPay Sandbox',
                ),
              ),
            OutlinedButton(
              onPressed: _busy ? null : _check,
              child: const Text('Kiểm tra kết quả'),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
