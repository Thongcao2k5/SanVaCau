import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../addresses/models/customer_address.dart';
import '../../addresses/pages/address_list_page.dart';
import '../../branches/data/branch_api.dart';
import '../../branches/models/branch.dart';
import '../../cart/models/cart.dart';
import '../../payments/data/payment_api.dart';
import '../../payments/models/payment.dart';
import '../../payments/pages/mock_payment_page.dart';
import '../../vouchers/data/voucher_api.dart';
import '../../vouchers/models/voucher_quote.dart';
import '../data/fulfillment_api.dart';
import '../data/order_api.dart';
import '../models/order.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({required this.cart, super.key});

  final Cart cart;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final BranchApi _branchApi;
  late final OrderApi _orderApi;
  late final FulfillmentApi _fulfillmentApi;
  late final PaymentApi _paymentApi;
  late final VoucherApi _voucherApi;
  final TextEditingController _voucherController = TextEditingController();

  late Future<List<Branch>> _branchesFuture;
  Branch? _selectedBranch;
  String _fulfillmentType = 'PICKUP';
  CustomerAddress? _selectedAddress;
  String _paymentProvider = 'CASH';
  VoucherQuote? _voucherQuote;
  bool _isValidatingVoucher = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _branchApi = BranchApi();
    _orderApi = OrderApi();
    _fulfillmentApi = FulfillmentApi();
    _paymentApi = PaymentApi();
    _voucherApi = VoucherApi();
    _branchesFuture = _branchApi.getBranches();
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  void _reloadBranches() {
    setState(() {
      _branchesFuture = _branchApi.getBranches();
    });
  }

  Future<void> _submitOrder() async {
    if (_selectedBranch == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng chọn cơ sở')));
      return;
    }

    if (_fulfillmentType == 'DELIVERY' && _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ nhận hàng')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    Order? createdOrder;
    Payment? payment;
    try {
      createdOrder = await _orderApi.createOrder(branchId: _selectedBranch!.id);

      if (_fulfillmentType == 'DELIVERY') {
        await _fulfillmentApi.createDelivery(
          orderId: createdOrder.id,
          addressId: _selectedAddress!.id,
        );
      } else {
        await _fulfillmentApi.createPickup(orderId: createdOrder.id);
      }

      if (_voucherQuote != null) {
        await _voucherApi.applyOrderVoucher(
          code: _voucherQuote!.code,
          orderId: createdOrder.id,
          amount: widget.cart.totalAmount,
        );
      }

      payment = await _paymentApi.createPayment(
        targetType: 'ORDER',
        targetId: createdOrder.id,
        provider: _paymentProvider,
      );
      if (!mounted) return;

      if (_paymentProvider == 'MOCK') {
        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => MockPaymentPage(payment: payment!)),
        );
        if (!mounted) return;
        if (paid != true) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Đơn hàng đã được lưu'),
              content: const Text(
                'Thanh toán chưa hoàn tất. Bạn có thể xem trạng thái trong Lịch sử thanh toán.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hoàn tất'),
                ),
              ],
            ),
          );
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Đặt hàng thành công'),
          content: Text(
            _fulfillmentType == 'DELIVERY'
                ? 'Đơn hàng đã được ghi nhận và sẽ giao đến địa chỉ bạn chọn.'
                : _paymentProvider == 'CASH'
                ? 'Đơn hàng đã được ghi nhận. Bạn sẽ thanh toán khi nhận tại cơ sở.'
                : 'Đơn hàng đã được ghi nhận và thanh toán thành công.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Hoàn tất'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Close checkout page returning true
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (createdOrder != null) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Đơn hàng đã được tạo'),
              content: Text(
                'Đơn #${createdOrder!.id} đã được tạo nhưng bước giao nhận hoặc thanh toán chưa hoàn tất. Vui lòng kiểm tra lại trong đơn hàng của tôi.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đã hiểu'),
                ),
              ],
            ),
          );
          if (mounted) Navigator.of(context).pop(true);
        } else if (e.statusCode == 401) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đăng nhập để đặt hàng')),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatMoney(double value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < rounded.length; i++) {
      final reverseIndex = rounded.length - i;
      buffer.write(rounded[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} đ';
  }

  Future<void> _selectAddress() async {
    final address = await Navigator.of(context).push<CustomerAddress>(
      MaterialPageRoute(
        builder: (_) => const AddressListPage(selectionMode: true),
      ),
    );
    if (address != null && mounted) {
      setState(() => _selectedAddress = address);
    }
  }

  Future<void> _validateVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty || _isValidatingVoucher) return;
    setState(() => _isValidatingVoucher = true);
    try {
      final quote = await _voucherApi.validateOrderVoucher(
        code: code,
        amount: widget.cart.totalAmount,
      );
      if (!mounted) return;
      setState(() => _voucherQuote = quote);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã áp dụng mã giảm giá')));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _voucherQuote = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isValidatingVoucher = false);
    }
  }

  void _clearVoucher() {
    setState(() {
      _voucherQuote = null;
      _voucherController.clear();
    });
  }

  double get _discountAmount => _voucherQuote?.discountAmount ?? 0;

  double get _payableAmount =>
      widget.cart.totalAmount -
      _discountAmount +
      (_fulfillmentType == 'DELIVERY' ? 30000 : 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: FutureBuilder<List<Branch>>(
        future: _branchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.message
                : 'Không thể tải danh sách cơ sở';

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off_outlined,
                      size: 44,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Có lỗi xảy ra',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reloadBranches,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final branches = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Cơ sở lấy hàng',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                          const Divider(height: 1),
                          if (branches.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Không có cơ sở nào khả dụng lúc này.',
                              ),
                            )
                          else
                            ...branches.map((branch) {
                              final isSelected =
                                  _selectedBranch?.id == branch.id;
                              return ListTile(
                                leading: Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                title: Text(
                                  branch.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(branch.address),
                                onTap: () {
                                  setState(() {
                                    _selectedBranch = branch;
                                  });
                                },
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã giảm giá',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _voucherController,
                                    enabled:
                                        !_isValidatingVoucher &&
                                        _voucherQuote == null,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _validateVoucher(),
                                    decoration: const InputDecoration(
                                      hintText: 'Nhập mã voucher',
                                      prefixIcon: Icon(
                                        Icons.local_offer_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_voucherQuote == null)
                                  FilledButton(
                                    onPressed: _isValidatingVoucher
                                        ? null
                                        : _validateVoucher,
                                    child: _isValidatingVoucher
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.onPrimary,
                                            ),
                                          )
                                        : const Text('Áp dụng'),
                                  )
                                else
                                  IconButton(
                                    tooltip: 'Bỏ voucher',
                                    onPressed: _clearVoucher,
                                    icon: const Icon(Icons.close),
                                  ),
                              ],
                            ),
                            if (_voucherQuote != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.successSoft,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.success.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _voucherQuote!.title.isEmpty
                                                ? _voucherQuote!.code
                                                : _voucherQuote!.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Giảm ${_formatMoney(_discountAmount)}',
                                            style: const TextStyle(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phương thức thanh toán',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'CASH',
                                  icon: Icon(Icons.payments_outlined),
                                  label: Text('Tiền mặt'),
                                ),
                                ButtonSegment(
                                  value: 'MOCK',
                                  icon: Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                  label: Text('Mô phỏng'),
                                ),
                              ],
                              selected: {_paymentProvider},
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _paymentProvider = selection.first;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _paymentProvider == 'CASH'
                                  ? 'Thanh toán khi nhận hàng.'
                                  : 'Dùng cổng mô phỏng để trình diễn luồng thanh toán.',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hình thức nhận hàng',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'PICKUP',
                                  icon: Icon(Icons.storefront_outlined),
                                  label: Text('Tại cửa hàng'),
                                ),
                                ButtonSegment(
                                  value: 'DELIVERY',
                                  icon: Icon(Icons.local_shipping_outlined),
                                  label: Text('Giao tận nơi'),
                                ),
                              ],
                              selected: {_fulfillmentType},
                              onSelectionChanged: (selection) {
                                setState(() {
                                  _fulfillmentType = selection.first;
                                });
                              },
                            ),
                            if (_fulfillmentType == 'DELIVERY') ...[
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: _selectAddress,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.borderMuted,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _selectedAddress == null
                                            ? const Text(
                                                'Chọn địa chỉ nhận hàng',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${_selectedAddress!.recipientName} · ${_selectedAddress!.phone}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    _selectedAddress!
                                                        .fullAddress,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Phí giao hàng'),
                                  Text(
                                    '30.000 đ',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Tóm tắt đơn hàng',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                          const Divider(height: 1),
                          ...widget.cart.items.map(
                            (item) => ListTile(
                              title: Text(
                                '${item.variant.product.name} - ${item.variant.variantName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text('Số lượng: ${item.quantity}'),
                              trailing: Text(
                                _formatMoney(item.lineTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          if (_voucherQuote != null) ...[
                            const Divider(height: 1),
                            ListTile(
                              title: const Text('Giảm giá'),
                              trailing: Text(
                                '-${_formatMoney(_discountAmount)}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tổng cộng',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              _formatMoney(_payableAmount),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed:
                            _isSubmitting ||
                                _selectedBranch == null ||
                                (_fulfillmentType == 'DELIVERY' &&
                                    _selectedAddress == null)
                            ? null
                            : _submitOrder,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    AppColors.onPrimary,
                                  ),
                                ),
                              )
                            : const Text('Đặt hàng'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
