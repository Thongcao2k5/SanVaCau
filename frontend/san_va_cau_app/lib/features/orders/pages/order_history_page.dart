import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page_components.dart';
import '../data/order_api.dart';
import '../models/order.dart';
import 'order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({this.orderApi, super.key});

  final OrderApi? orderApi;

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late final OrderApi _orderApi;
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _orderApi = widget.orderApi ?? OrderApi();
    _ordersFuture = _orderApi.getMyOrders();
  }

  Future<void> _reloadOrders() async {
    final future = _orderApi.getMyOrders();
    setState(() {
      _ordersFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng của tôi')),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.message
                : 'Không thể tải lịch sử đơn hàng';

            return AppStateView(
              icon: Icons.receipt_long_outlined,
              title: 'Có lỗi xảy ra',
              message: message,
              actionLabel: 'Thử lại',
              onAction: _reloadOrders,
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return AppStateView(
              icon: Icons.shopping_bag_outlined,
              title: 'Chưa có đơn hàng',
              message: 'Các đơn hàng của bạn sẽ xuất hiện tại đây.',
              actionLabel: 'Tải lại',
              onAction: _reloadOrders,
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: RefreshIndicator(
              onRefresh: _reloadOrders,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _OrderCard(
                    order: order,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => OrderDetailPage(order: order),
                        ),
                      );
                      await _reloadOrders();
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  String _formatMoney(String value) {
    final doubleValue = double.tryParse(value) ?? 0;
    final rounded = doubleValue.round().toString();
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không xác định';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  (String, Color, Color) _statusStyle(String status) {
    return switch (status.toUpperCase()) {
      'READY_FOR_PICKUP' => (
        'Sẵn sàng nhận',
        AppColors.info,
        AppColors.infoSoft,
      ),
      'COMPLETED' => ('Hoàn tất', AppColors.success, AppColors.successSoft),
      'CANCELLED' => ('Đã hủy', AppColors.primary, AppColors.primarySoft),
      _ => ('Chờ xác nhận', AppColors.warning, AppColors.warningSoft),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor, statusBackground) = _statusStyle(
      order.status,
    );

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đơn hàng #${order.id}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (order.branch != null)
                Row(
                  children: [
                    const Icon(
                      Icons.store_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.branch!.name,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.items.length} sản phẩm'),
                  Text(
                    _formatMoney(order.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
