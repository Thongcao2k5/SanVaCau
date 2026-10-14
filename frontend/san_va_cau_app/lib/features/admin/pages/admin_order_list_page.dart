import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import 'package:san_va_cau_app/core/theme/app_colors.dart';
import 'package:san_va_cau_app/features/orders/data/order_api.dart';
import 'package:san_va_cau_app/features/orders/models/order.dart';

import 'admin_order_detail_page.dart';

class AdminOrderListPage extends StatefulWidget {
  const AdminOrderListPage({super.key, this.orderApi});

  final OrderApi? orderApi;

  @override
  State<AdminOrderListPage> createState() => _AdminOrderListPageState();
}

class _AdminOrderListPageState extends State<AdminOrderListPage> {
  late final OrderApi _api = widget.orderApi ?? OrderApi();
  Future<List<Order>>? _ordersFuture;
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = _api.getAdminOrders(
        status: _selectedStatus.isNotEmpty ? _selectedStatus : null,
      );
    });
  }

  Future<void> _refresh() async {
    _loadOrders();
    await _ordersFuture;
  }

  void _onStatusChanged(String status) {
    if (_selectedStatus == status) return;
    setState(() {
      _selectedStatus = status;
    });
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        backgroundColor: AdminTheme.canvas,
        appBar: AppBar(
          title: const Text('Quản lý đơn hàng'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildFilters(),
              Expanded(
                child: FutureBuilder<List<Order>>(
                  future: _ordersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Đang tải đơn hàng'),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      return AdminStateView(
                        icon: Icons.cloud_off_rounded,
                        title: 'Không thể tải danh sách đơn hàng',
                        actionLabel: 'Thử lại',
                        onAction: _loadOrders,
                      );
                    }

                    final orders = snapshot.data ?? [];

                    if (orders.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: const AdminStateView(
                                icon: Icons.shopping_bag_rounded,
                                title: 'Không có đơn hàng nào',
                                message: 'Thử chọn trạng thái khác.',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _OrderCard(
                            order: orders[index],
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminOrderDetailPage(
                                    orderId: orders[index].id,
                                    orderApi: _api,
                                  ),
                                ),
                              );
                              if (result == true) {
                                _loadOrders();
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('Tất cả', ''),
          const SizedBox(width: 8),
          _buildFilterChip('Chờ xử lý', 'PENDING'),
          const SizedBox(width: 8),
          _buildFilterChip('Chờ nhận hàng', 'READY_FOR_PICKUP'),
          const SizedBox(width: 8),
          _buildFilterChip('Hoàn tất', 'COMPLETED'),
          const SizedBox(width: 8),
          _buildFilterChip('Đã hủy', 'CANCELLED'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onStatusChanged(value),
      backgroundColor: AdminTheme.surface,
      selectedColor: AppColors.primarySoft,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
        color: isSelected ? AdminTheme.primaryText : AdminTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context) {
    final customerName = order.customer?.fullName ?? 'Khách lẻ';
    final customerPhone = order.customer?.phone ?? '';

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.cardRadius),
        side: const BorderSide(color: AdminTheme.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    'Đơn #${order.id}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AdminStatusBadge(
                    label: _getStatusLabel(order.status),
                    tone: _getStatusTone(order.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: AdminTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customerPhone.isNotEmpty
                          ? '$customerName - $customerPhone'
                          : customerName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 16,
                    color: AdminTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.branch?.name ?? 'Không xác định',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: AdminTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(order.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    'Tổng tiền',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AdminTheme.textSecondary),
                  ),
                  Text(
                    _formatCurrency(order.totalAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
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
