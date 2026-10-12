import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/theme/app_colors.dart';
import 'package:san_va_cau_app/features/orders/data/order_api.dart';
import 'package:san_va_cau_app/features/orders/data/fulfillment_api.dart';
import 'package:san_va_cau_app/features/orders/models/order.dart';
import 'package:san_va_cau_app/features/orders/models/order_fulfillment.dart';

class AdminOrderDetailPage extends StatefulWidget {
  const AdminOrderDetailPage({
    super.key,
    required this.orderId,
    this.orderApi,
    this.fulfillmentApi,
  });

  final String orderId;
  final OrderApi? orderApi;
  final FulfillmentApi? fulfillmentApi;

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  late final OrderApi _api = widget.orderApi ?? OrderApi();
  late final FulfillmentApi _fulfillmentApi =
      widget.fulfillmentApi ?? FulfillmentApi();
  Future<Order>? _orderFuture;
  Future<OrderFulfillment?>? _fulfillmentFuture;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  void _loadOrder() {
    setState(() {
      _orderFuture = _api.getAdminOrderById(widget.orderId);
      _fulfillmentFuture = _fulfillmentApi.getForOrder(widget.orderId);
    });
  }

  String _formatCurrency(String amount) {
    final number = double.tryParse(amount) ?? 0;
    final text = number.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(text[i]);
    }
    return '${buffer.toString()} đ';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không xác định';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'READY_FOR_PICKUP':
        return 'Chờ nhận hàng';
      case 'COMPLETED':
        return 'Hoàn tất';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  AdminStatusTone _getStatusTone(String status) => switch (status) {
    'PENDING' => AdminStatusTone.warning,
    'READY_FOR_PICKUP' => AdminStatusTone.info,
    'COMPLETED' => AdminStatusTone.success,
    'CANCELLED' => AdminStatusTone.danger,
    _ => AdminStatusTone.neutral,
  };

  Future<void> _updateStatus(String newStatus) async {
    if (_isUpdating) return;

    if (newStatus == 'COMPLETED' || newStatus == 'CANCELLED') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            newStatus == 'COMPLETED' ? 'Xác nhận hoàn tất' : 'Xác nhận hủy đơn',
          ),
          content: Text(
            newStatus == 'COMPLETED'
                ? 'Bạn có chắc chắn muốn hoàn tất đơn hàng này?'
                : 'Bạn có chắc chắn muốn hủy đơn hàng này?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bỏ qua'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: newStatus == 'CANCELLED'
                    ? AppColors.primary
                    : AppColors.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted || _isUpdating) return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _api.updateAdminOrderStatus(id: widget.orderId, status: newStatus);
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thành công')),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra')));
      }
    } finally {
      if (mounted && _isUpdating) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        backgroundColor: AdminTheme.canvas,
        appBar: AppBar(
          title: const Text('Chi tiết đơn hàng'),
          backgroundColor: AdminTheme.graphite,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: FutureBuilder<Order>(
            future: _orderFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError && !snapshot.hasData) {
                return AdminStateView(
                  icon: Icons.cloud_off_rounded,
                  title: 'Không thể tải chi tiết đơn hàng',
                  actionLabel: 'Thử lại',
                  onAction: _loadOrder,
                );
              }

              final order = snapshot.data;
              if (order == null) return const SizedBox.shrink();

              final isFinal =
                  order.status == 'COMPLETED' || order.status == 'CANCELLED';
              final customerName = order.customer?.fullName ?? 'Khách lẻ';
              final customerPhone = order.customer?.phone ?? 'Không có SĐT';

              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            _loadOrder();
                            await _orderFuture;
                          },
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Header Info
                              Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AdminTheme.cardRadius,
                                  ),
                                  side: BorderSide(color: AdminTheme.border),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          Text(
                                            'Đơn #${order.id}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          AdminStatusBadge(
                                            label: _getStatusLabel(
                                              order.status,
                                            ),
                                            tone: _getStatusTone(order.status),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _buildInfoRow(
                                        Icons.person_rounded,
                                        'Khách hàng:',
                                        customerName,
                                      ),
                                      if (customerPhone.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: _buildInfoRow(
                                            Icons.phone_rounded,
                                            'SĐT:',
                                            customerPhone,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        Icons.storefront_rounded,
                                        'Chi nhánh:',
                                        order.branch?.name ?? 'Không xác định',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              FutureBuilder<OrderFulfillment?>(
                                future: _fulfillmentFuture,
                                builder: (context, fulfillmentSnapshot) {
                                  if (fulfillmentSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Card(
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.local_shipping_rounded,
                                        ),
                                        title: Text('Thông tin giao nhận'),
                                        subtitle: Text('Đang tải...'),
                                      ),
                                    );
                                  }
                                  if (fulfillmentSnapshot.hasError) {
                                    return const Card(
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.local_shipping_rounded,
                                        ),
                                        title: Text('Thông tin giao nhận'),
                                        subtitle: Text(
                                          'Không thể tải thông tin giao nhận',
                                        ),
                                      ),
                                    );
                                  }
                                  return _FulfillmentCard(
                                    fulfillment: fulfillmentSnapshot.data,
                                    branchName: order.branch?.name,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Timestamps
                              Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AdminTheme.cardRadius,
                                  ),
                                  side: BorderSide(color: AdminTheme.border),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Thời gian',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildTimeRow('Tạo đơn', order.createdAt),
                                      if (order.readyAt != null) ...[
                                        const SizedBox(height: 8),
                                        _buildTimeRow(
                                          'Sẵn sàng nhận',
                                          order.readyAt,
                                        ),
                                      ],
                                      if (order.completedAt != null) ...[
                                        const SizedBox(height: 8),
                                        _buildTimeRow(
                                          'Hoàn tất',
                                          order.completedAt,
                                        ),
                                      ],
                                      if (order.cancelledAt != null) ...[
                                        const SizedBox(height: 8),
                                        _buildTimeRow(
                                          'Đã hủy',
                                          order.cancelledAt,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Items
                              Text(
                                'Sản phẩm',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ...order.items.map((item) {
                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: AdminTheme.border),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: item.imageUrl != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    item.imageUrl!,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, _, _) =>
                                                        const Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          color: Colors.grey,
                                                        ),
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.inventory_2_outlined,
                                                  color: Colors.grey,
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.variantName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AdminTheme
                                                          .textSecondary,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 12,
                                                runSpacing: 8,
                                                children: [
                                                  Text(
                                                    '${_formatCurrency(item.unitPrice)} x ${item.quantity}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium,
                                                  ),
                                                  Text(
                                                    _formatCurrency(
                                                      ((double.tryParse(
                                                                    item.unitPrice,
                                                                  ) ??
                                                                  0) *
                                                              item.quantity)
                                                          .toString(),
                                                    ),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: 16),
                              // Total Amount
                              Card(
                                elevation: 0,
                                color: AppColors.primary.withValues(
                                  alpha: 0.05,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AdminTheme.cardRadius,
                                  ),
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      Text(
                                        'Tổng cộng',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        _formatCurrency(order.totalAmount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isFinal)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AdminTheme.surface,
                            border: const Border(
                              top: BorderSide(color: AdminTheme.border),
                            ),
                          ),
                          child: SafeArea(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 500;
                                Widget action(
                                  String label,
                                  String status, {
                                  bool secondary = false,
                                }) => SizedBox(
                                  width: narrow
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - 16) / 3,
                                  child: ElevatedButton(
                                    onPressed: _isUpdating
                                        ? null
                                        : () => _updateStatus(status),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(48, 52),
                                      backgroundColor: secondary
                                          ? AppColors.primarySoft
                                          : AdminTheme.primary,
                                      foregroundColor: secondary
                                          ? AdminTheme.primaryText
                                          : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AdminTheme.compactRadius,
                                        ),
                                      ),
                                    ),
                                    child: Text(label),
                                  ),
                                );
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (order.status != 'READY_FOR_PICKUP')
                                      action(
                                        'Sẵn sàng nhận hàng',
                                        'READY_FOR_PICKUP',
                                      ),
                                    action('Hoàn tất đơn', 'COMPLETED'),
                                    action(
                                      'Hủy đơn',
                                      'CANCELLED',
                                      secondary: true,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_isUpdating)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black26,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: AdminTheme.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AdminTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );
  Widget _buildTimeRow(String label, DateTime? date) => Wrap(
    spacing: 12,
    runSpacing: 4,
    children: [
      Text(label, style: const TextStyle(color: AdminTheme.textSecondary)),
      Text(
        _formatDate(date),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ],
  );
}

class _FulfillmentCard extends StatelessWidget {
  const _FulfillmentCard({this.fulfillment, this.branchName});

  final OrderFulfillment? fulfillment;
  final String? branchName;

  @override
  Widget build(BuildContext context) {
    final data = fulfillment;
    final isDelivery = data?.isDelivery == true;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.cardRadius),
        side: const BorderSide(color: AdminTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDelivery
                      ? Icons.local_shipping_rounded
                      : Icons.storefront_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDelivery ? 'Giao hàng tận nơi' : 'Nhận tại chi nhánh',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isDelivery) ...[
              Text(data?.recipientName ?? 'Chưa có tên người nhận'),
              if (data?.phone?.isNotEmpty == true) Text(data!.phone!),
              const SizedBox(height: 4),
              Text(
                data?.fullAddress.isNotEmpty == true
                    ? data!.fullAddress
                    : 'Chưa có địa chỉ giao hàng',
                style: const TextStyle(color: AdminTheme.textSecondary),
              ),
              if (data?.note?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text('Ghi chú: ${data!.note}'),
              ],
            ] else
              Text(
                branchName ?? 'Chi nhánh nhận hàng',
                style: const TextStyle(color: AdminTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
