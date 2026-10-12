import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/momo_payment_service.dart';
import '../data/payment_api.dart';
import '../models/payment.dart';

class MomoPaymentPage extends StatefulWidget {
  const MomoPaymentPage({required this.payment, super.key});
  final Payment payment;
  @override
  State<MomoPaymentPage> createState() => _MomoPaymentPageState();
}

class _MomoPaymentPageState extends State<MomoPaymentPage>
    with WidgetsBindingObserver {
  final _api = PaymentApi();
  final _momo = MomoPaymentService();
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
          provider: 'MOMO_SANDBOX',
        );
      }
      if (_payment.status == 'PAID') {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      await _momo.openSandbox(_payment.checkoutUrl ?? '');
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không mở được trang MoMo Sandbox. Vui lòng thử lại.',
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
      final payment = await _api.checkMomo(_payment.id);
      if (!mounted) return;
      setState(() => _payment = payment);
      if (payment.status == 'PAID') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MoMo Sandbox thanh toán thành công')),
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
      appBar: AppBar(title: const Text('MoMo Sandbox')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Color(0xFFA50064),
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
              'Môi trường thử nghiệm MoMo Sandbox. Dùng tài khoản kiểm thử MoMo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              _payment.status == 'FAILED'
                  ? 'Thanh toán thất bại hoặc đã hủy.'
                  : 'Chờ xác nhận từ MoMo.',
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
                      : 'Mở MoMo Sandbox',
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
