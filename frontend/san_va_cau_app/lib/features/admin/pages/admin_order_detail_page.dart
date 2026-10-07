import 'package:flutter/material.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/theme/app_colors.dart';
import 'package:san_va_cau_app/features/orders/data/order_api.dart';
import 'package:san_va_cau_app/features/orders/models/order.dart';

class AdminOrderDetailPage extends StatefulWidget {
  const AdminOrderDetailPage({super.key, required this.orderId, this.orderApi});

  final String orderId;
  final OrderApi? orderApi;

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  late final OrderApi _api = widget.orderApi ?? OrderApi();
  Future<Order>? _orderFuture;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  void _loadOrder() {
    setState(() {
      _orderFuture = _api.getAdminOrderById(widget.orderId);
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;
      case 'READY_FOR_PICKUP':
        return AppColors.info;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

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

      if (confirmed != true) return;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng'), centerTitle: true),
      body: FutureBuilder<Order>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Không thể tải chi tiết đơn hàng'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrder,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final order = snapshot.data;
          if (order == null) return const SizedBox.shrink();

          final isFinal =
              order.status == 'COMPLETED' || order.status == 'CANCELLED';
          final statusColor = _getStatusColor(order.status);
          final customerName = order.customer?.fullName ?? 'Khách lẻ';
          final customerPhone = order.customer?.phone ?? 'Không có SĐT';

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  _loadOrder();
                  await _orderFuture;
                },
                child: ListView(
                  padding: const EdgeInsets.all(16).copyWith(
                    bottom: isFinal
                        ? 16
                        : 100, // Extra padding for fixed bottom bar if needed
                  ),
                  children: [
                    // Header Info
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đơn #${order.id}',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Text(
                                    _getStatusLabel(order.status),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.person_outline,
                              'Khách hàng:',
                              customerName,
                            ),
                            if (customerPhone.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: _buildInfoRow(
                                  Icons.phone_outlined,
                                  'SĐT:',
                                  customerPhone,
                                ),
                              ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.storefront_outlined,
                              'Chi nhánh:',
                              order.branch?.name ?? 'Không xác định',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timestamps
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thời gian',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _buildTimeRow('Tạo đơn', order.createdAt),
                            if (order.readyAt != null) ...[
                              const SizedBox(height: 8),
                              _buildTimeRow('Sẵn sàng nhận', order.readyAt),
                            ],
                            if (order.completedAt != null) ...[
                              const SizedBox(height: 8),
                              _buildTimeRow('Hoàn tất', order.completedAt),
                            ],
                            if (order.cancelledAt != null) ...[
                              const SizedBox(height: 8),
                              _buildTimeRow('Đã hủy', order.cancelledAt),
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
                          side: BorderSide(color: Colors.grey.shade200),
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: item.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.image_not_supported,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${_formatCurrency(item.unitPrice)} x ${item.quantity}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        Text(
                                          _formatCurrency(
                                            ((double.tryParse(item.unitPrice) ??
                                                        0) *
                                                    item.quantity)
                                                .toString(),
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
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
                      color: AppColors.primary.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng cộng',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatCurrency(order.totalAmount),
                              style: Theme.of(context).textTheme.titleLarge
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
              if (!isFinal)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          if (order.status != 'READY_FOR_PICKUP')
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isUpdating
                                    ? null
                                    : () => _updateStatus('READY_FOR_PICKUP'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.info,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Sẵn sàng nhận hàng'),
                              ),
                            ),
                          if (order.status != 'READY_FOR_PICKUP')
                            const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateStatus('COMPLETED'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Hoàn tất đơn'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateStatus('CANCELLED'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Hủy đơn'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow(String label, DateTime? date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          _formatDate(date),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
