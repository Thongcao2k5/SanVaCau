import 'package:flutter/material.dart';

import '../data/admin_dashboard_api.dart';
import '../models/admin_dashboard.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';
import 'admin_booking_list_page.dart';
import 'admin_inventory_list_page.dart';
import 'admin_order_list_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    this.dashboardApi,
    this.embedded = false,
  });

  final AdminDashboardApi? dashboardApi;
  final bool embedded;

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
    final future = _api.getSummary();
    setState(() {
      _dashboardFuture = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = ColoredBox(
      color: AdminTheme.canvas,
      child: FutureBuilder<AdminDashboard>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return AdminStateView(
              icon: Icons.cloud_off_rounded,
              title: 'Không thể tải dữ liệu quản trị',
              message: 'Kiểm tra kết nối rồi thử tải lại tổng quan.',
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _dashboardFuture;
            },
            child: _DashboardContent(data: snapshot.data!, onRefresh: _reload),
          );
        },
      ),
    );

    if (widget.embedded) {
      return SafeArea(
        child: Column(
          children: [
            AdminPageHeader(
              title: 'Trung tâm vận hành',
              subtitle: 'Theo dõi nhanh hoạt động hôm nay',
              action: IconButton(
                tooltip: 'Tải lại',
                onPressed: _reload,
                color: Colors.white,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AdminTheme.canvas,
      appBar: AppBar(
        title: const Text('Tổng quan quản trị'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.onRefresh});

  final AdminDashboard data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        _ScopeBanner(data: data),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final singleColumn = constraints.maxWidth < 340 || textScale >= 1.3;
            final cardWidth = singleColumn
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'Lịch đặt hôm nay',
                    value: '${data.bookings.total}',
                    detail: '${data.bookings.booked} đang chờ',
                    icon: Icons.calendar_month_rounded,
                    color: AdminTheme.info,
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
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'Đơn hàng hôm nay',
                    value: '${data.orders.total}',
                    detail: '${data.orders.pending} chờ xử lý',
                    icon: Icons.receipt_long_rounded,
                    color: AdminTheme.primary,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminOrderListPage(),
                        ),
                      );
                      onRefresh();
                    },
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'Doanh thu hoàn tất',
                    value: _money(data.orders.revenueCompleted),
                    detail: '${data.orders.completed} đơn hoàn tất',
                    icon: Icons.payments_rounded,
                    color: AdminTheme.success,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _MetricCard(
                    label: 'Sắp hết hàng',
                    value: '${data.inventory.lowStockCount}',
                    detail: '${data.courts.active} sân hoạt động',
                    icon: Icons.inventory_2_rounded,
                    color: AdminTheme.warning,
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
                ),
              ],
            );
          },
        ),
        if (data.inventory.lowStockItems.isNotEmpty) ...[
          const SizedBox(height: 26),
          const _SectionTitle(
            title: 'Tồn kho cần chú ý',
            subtitle: 'Ưu tiên kiểm tra các mặt hàng dưới ngưỡng',
          ),
          const SizedBox(height: 10),
          AdminSurface(
            padding: EdgeInsets.zero,
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
                    const Divider(height: 1, color: AdminTheme.border),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 26),
        const _SectionTitle(
          title: 'Hoạt động gần đây',
          subtitle: 'Lịch đặt và đơn hàng mới nhất',
        ),
        const SizedBox(height: 10),
        if (data.latestBookings.isEmpty && data.latestOrders.isEmpty)
          const AdminSurface(
            child: AdminStateView(
              icon: Icons.inbox_rounded,
              title: 'Chưa có hoạt động gần đây',
              message: 'Dữ liệu mới sẽ xuất hiện tại đây.',
            ),
          )
        else ...[
          for (final booking in data.latestBookings)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityTile(
                icon: Icons.sports_tennis_rounded,
                title: 'Lịch #${booking.id} • ${booking.courtName}',
                subtitle:
                    '${booking.customerName} • ${booking.branchName} • ${booking.date}',
                status: booking.status,
              ),
            ),
          for (final order in data.latestOrders)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityTile(
                icon: Icons.shopping_bag_rounded,
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

class _ScopeBanner extends StatelessWidget {
  const _ScopeBanner({required this.data});

  final AdminDashboard data;

  @override
  Widget build(BuildContext context) {
    final scope = data.branchId == null
        ? 'Toàn hệ thống'
        : 'Chi nhánh #${data.branchId}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AdminIconBox(
              icon: Icons.today_rounded,
              color: AdminTheme.info,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scope,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AdminTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.date,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AdminTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AdminStatusBadge(
          label: _roleLabel(data.role),
          tone: AdminStatusTone.neutral,
        ),
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
    return AdminSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminIconBox(icon: icon, color: color, size: 38),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AdminTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AdminTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AdminTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AdminTheme.textSecondary),
        ),
      ],
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
      minTileHeight: AdminTheme.touchTarget,
      leading: const AdminIconBox(
        icon: Icons.warning_amber_rounded,
        color: AdminTheme.warning,
        size: 40,
      ),
      title: Text(
        item.variantName.isEmpty
            ? item.productName
            : '${item.productName} • ${item.variantName}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${item.branchName} • SKU ${item.sku}'),
      trailing: AdminStatusBadge(
        label: '${item.quantity} còn lại',
        tone: AdminStatusTone.warning,
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
    return AdminSurface(
      child: Row(
        children: [
          AdminIconBox(icon: icon, color: AdminTheme.primary, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AdminTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: AdminStatusBadge(
              label: _statusLabel(status),
              tone: _statusTone(status),
            ),
          ),
        ],
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

String _roleLabel(String role) {
  return switch (role) {
    'ADMIN' => 'Quản trị viên',
    'BRANCH_MANAGER' => 'Quản lý chi nhánh',
    'STAFF' => 'Nhân viên',
    _ => role,
  };
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

AdminStatusTone _statusTone(String status) {
  return switch (status) {
    'PENDING' || 'BOOKED' || 'READY_FOR_PICKUP' => AdminStatusTone.warning,
    'CHECKED_IN' => AdminStatusTone.info,
    'COMPLETED' => AdminStatusTone.success,
    'CANCELLED' => AdminStatusTone.danger,
    _ => AdminStatusTone.neutral,
  };
}
