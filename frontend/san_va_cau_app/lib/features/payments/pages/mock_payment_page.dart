import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/payment_api.dart';
import '../models/payment.dart';

class MockPaymentPage extends StatefulWidget {
  const MockPaymentPage({required this.payment, super.key});

  final Payment payment;

  @override
  State<MockPaymentPage> createState() => _MockPaymentPageState();
}

class _MockPaymentPageState extends State<MockPaymentPage> {
  final PaymentApi _paymentApi = PaymentApi();
  bool _isSubmitting = false;

  String _formatMoney(String value) {
    final digits = (double.tryParse(value) ?? 0).round().toString();
    return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} đ';
  }

  Future<void> _complete(bool success) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      if (success) {
        await _paymentApi.markSuccess(widget.payment.id);
      } else {
        await _paymentApi.markFailed(widget.payment.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Thanh toán thành công'
                : 'Đã mô phỏng thanh toán thất bại',
          ),
        ),
      );
      Navigator.of(context).pop(success);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Thanh toán mô phỏng')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatMoney(widget.payment.amount),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Thanh toán cho ${widget.payment.targetType == 'ORDER' ? 'đơn hàng' : 'lịch đặt'} #${widget.payment.targetId}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _PaymentRow(
                        label: 'Mã giao dịch',
                        value:
                            widget.payment.transactionRef ?? widget.payment.id,
                      ),
                      const Divider(height: 24),
                      const _PaymentRow(
                        label: 'Nhà cung cấp',
                        value: 'Mô phỏng',
                      ),
                      const Divider(height: 24),
                      const _PaymentRow(
                        label: 'Trạng thái',
                        value: 'Chờ thanh toán',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : () => _complete(true),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Xác nhận thanh toán thành công'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => _complete(false),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Mô phỏng thanh toán thất bại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
