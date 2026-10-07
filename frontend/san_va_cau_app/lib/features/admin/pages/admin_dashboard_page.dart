import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/admin_dashboard_api.dart';
import '../models/admin_dashboard.dart';
import 'admin_booking_list_page.dart';
import 'admin_inventory_list_page.dart';
import 'admin_order_list_page.dart';
import 'admin_product_list_page.dart';
import 'admin_user_list_page.dart';
import 'admin_content_hub_page.dart';
import 'admin_report_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key, this.dashboardApi});

  final AdminDashboardApi? dashboardApi;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final AdminDashboardApi _api;
  late Future<AdminDashboard> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _api = widget.dashboardApi ?? AdminDashboardApi();
    _reload();
  }

  void _reload() {
    setState(() {
      _dashboardFuture = _api.getSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan quản trị'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<AdminDashboard>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _ErrorState(onRetry: _reload);
          }
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _dashboardFuture;
            },
            child: _DashboardContent(
              data: snapshot.data!,
              onRefresh: () {
                _reload();
              },
            ),
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.onRefresh});

  final AdminDashboard data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          data.branchId == null
              ? 'Toàn hệ thống • ${data.date}'
              : 'Chi nhánh #${data.branchId} • ${data.date}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.38,
          children: [
            _MetricCard(
              label: 'Lịch đặt hôm nay',
              value: '${data.bookings.total}',
              detail: '${data.bookings.booked} đang chờ',
              icon: Icons.calendar_month_outlined,
              color: AppColors.info,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminBookingListPage(),
                  ),
                );
                onRefresh();
              },
            ),
            _MetricCard(
              label: 'Đơn hàng hôm nay',
              value: '${data.orders.total}',
              detail: '${data.orders.pending} chờ xử lý',
              icon: Icons.receipt_long_outlined,
              color: AppColors.primary,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminOrderListPage()),
                );
                onRefresh();
              },
            ),
            _MetricCard(
              label: 'Doanh thu hoàn tất',
              value: _money(data.orders.revenueCompleted),
              detail: '${data.orders.completed} đơn hoàn tất',
              icon: Icons.payments_outlined,
              color: AppColors.success,
            ),
            _MetricCard(
              label: 'Sắp hết hàng',
              value: '${data.inventory.lowStockCount}',
              detail: '${data.courts.active} sân hoạt động',
              icon: Icons.inventory_2_outlined,
              color: AppColors.warning,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminInventoryListPage(
                      role: data.role,
                      assignedBranchId: data.branchId,
                    ),
                  ),
                );
                onRefresh();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const Icon(
              Icons.analytics_outlined,
              color: AppColors.primary,
            ),
            title: const Text(
              'Báo cáo tổng hợp',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Xem báo cáo tổng quan, sản phẩm và sân'),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminReportPage(role: data.role, branchId: data.branchId),
                ),
              );
              onRefresh();
            },
          ),
        ),
        if (data.role == 'ADMIN') ...[
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(
                Icons.inventory_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Quản lý sản phẩm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Thêm, sửa, xóa sản phẩm và phân loại'),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminProductListPage(isAdmin: true),
                  ),
                );
                onRefresh();
              },
            ),
          ),
        ],
        if (data.role == 'ADMIN') ...[
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(
                Icons.people_alt_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Quản lý nhân viên',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Tạo tài khoản, khóa tài khoản và đặt lại mật khẩu',
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminUserListPage(role: data.role),
                  ),
                );
                onRefresh();
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(
                Icons.art_track_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                'Quản lý nội dung',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Tin tức, banner, và gửi thông báo'),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminContentHubPage(role: data.role),
                  ),
                );
                onRefresh();
              },
            ),
          ),
        ],
        if (data.inventory.lowStockItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionTitle(title: 'Tồn kho cần chú ý'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < data.inventory.lowStockItems.length;
                  index++
                ) ...[
                  _LowStockTile(
                    item: data.inventory.lowStockItems[index],
                    data: data,
                    onRefresh: onRefresh,
                  ),
                  if (index < data.inventory.lowStockItems.length - 1)
                    const Divider(),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Hoạt động gần đây'),
        const SizedBox(height: 10),
        if (data.latestBookings.isEmpty && data.latestOrders.isEmpty)
          const _EmptyActivity()
        else ...[
          for (final booking in data.latestBookings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActivityTile(
                icon: Icons.sports_tennis_outlined,
                title: 'Lịch #${booking.id} • ${booking.courtName}',
                subtitle:
                    '${booking.customerName} • ${booking.branchName} • ${booking.date}',
                status: booking.status,
              ),
            ),
          for (final order in data.latestOrders)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActivityTile(
                icon: Icons.shopping_bag_outlined,
                title: 'Đơn #${order.id} • ${_money(order.totalAmount)}',
                subtitle: '${order.customerName} • ${order.branchName}',
                status: order.status,
              ),
            ),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({
    required this.item,
    required this.data,
    required this.onRefresh,
  });
  final AdminLowStockItem item;
  final AdminDashboard data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.warning_amber, color: AppColors.warning),
      title: Text(
        item.variantName.isEmpty
            ? item.productName
            : '${item.productName} • ${item.variantName}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${item.branchName} • SKU ${item.sku}'),
      trailing: Text(
        '${item.quantity}',
        style: const TextStyle(
          color: AppColors.warning,
          fontWeight: FontWeight.w800,
        ),
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminInventoryListPage(
              role: data.role,
              assignedBranchId: data.branchId,
            ),
          ),
        );
        onRefresh();
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(
          _statusLabel(status),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Chưa có hoạt động gần đây',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text('Không thể tải dữ liệu quản trị'),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

String _money(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '${buffer.toString()}đ';
}

String _statusLabel(String status) {
  return switch (status) {
    'PENDING' => 'Chờ xử lý',
    'BOOKED' => 'Đã đặt',
    'CHECKED_IN' => 'Đã nhận sân',
    'READY_FOR_PICKUP' => 'Chờ nhận',
    'COMPLETED' => 'Hoàn tất',
    'CANCELLED' => 'Đã hủy',
    _ => status,
  };
}
