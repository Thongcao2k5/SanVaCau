import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý đơn hàng'), centerTitle: true),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Không thể tải danh sách đơn hàng'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrders,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
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
                          child: const Center(
                            child: Text('Không có đơn hàng nào'),
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
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onStatusChanged(value),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final customerName = order.customer?.fullName ?? 'Khách lẻ';
    final customerPhone = order.customer?.phone ?? '';

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Đơn #${order.id}',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textSecondary,
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
                    Icons.storefront_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
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
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng tiền',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
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
