import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../payments/data/payment_api.dart';
import '../../payments/pages/momo_payment_page.dart';
import '../../payments/pages/vnpay_payment_page.dart';
import '../models/booking.dart';

Future<String?> chooseBookingPayment(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Thanh toán đặt sân'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'VNPAY_SANDBOX'),
            child: const Text('VNPAY'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'MOMO_SANDBOX'),
            child: const Text('MoMo'),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Thanh toán thử nghiệm Sandbox. Không thu tiền thật.'),
          ),
        ],
      ),
    );

class BookingPaymentPage extends StatefulWidget {
  const BookingPaymentPage({
    required this.bookings,
    required this.provider,
    this.paymentApi,
    super.key,
  });
  final List<Booking> bookings;
  final String provider;
  final PaymentApi? paymentApi;

  @override
  State<BookingPaymentPage> createState() => _BookingPaymentPageState();
}

class _BookingPaymentPageState extends State<BookingPaymentPage> {
  late final _api = widget.paymentApi ?? PaymentApi();
  final _paid = <String>{};
  bool _busy = false;
  String? _error;

  Future<void> _pay(Booking booking) async {
    if (_busy) return;
    final provider = await chooseBookingPayment(context);
    if (provider == null || !mounted) return;
    await _openPayment(booking, provider);
  }

  Future<void> _openPayment(Booking booking, String provider) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payment = await _api.createPayment(
        targetType: 'BOOKING',
        targetId: booking.id,
        provider: provider,
      );
      if (!mounted) return;
      final paid =
          payment.status == 'PAID' ||
          await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => provider == 'VNPAY_SANDBOX'
                      ? VnpayPaymentPage(payment: payment)
                      : MomoPaymentPage(payment: payment),
                ),
              ) ==
              true;
      if (mounted && paid) setState(() => _paid.add(booking.id));
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể mở thanh toán. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.bookings.isNotEmpty) {
        _openPayment(widget.bookings.first, widget.provider);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thanh toán đặt sân')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Lịch đặt đã được lưu. Chỉ ghi nhận đã thanh toán khi cổng thanh toán xác nhận.',
        ),
        if (widget.bookings.length > 1)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Bạn đã chọn nhiều sân. Thanh toán từng lịch đặt bên dưới.',
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        for (final booking in widget.bookings)
          Card(
            child: ListTile(
              title: Text('${booking.court.name} • #${booking.id}'),
              subtitle: Text('${booking.totalAmount} đ'),
              trailing: _paid.contains(booking.id)
                  ? const Text('Đã thanh toán')
                  : FilledButton(
                      onPressed: _busy ? null : () => _pay(booking),
                      child: const Text('Thanh toán'),
                    ),
            ),
          ),
        if (_busy) const Center(child: CircularProgressIndicator()),
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Nếu thoát trước khi trả tiền, mở Lịch sử đặt sân để thanh toán tiếp.',
          ),
        ),
      ],
    ),
  );
}
