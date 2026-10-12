import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../auth/data/auth_api.dart';
import '../auth/models/auth_user.dart';
import '../main/main_shell.dart';
import 'pages/admin_booking_list_page.dart';
import 'pages/admin_branch_list_page.dart';
import 'pages/admin_content_hub_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_inventory_list_page.dart';
import 'pages/admin_order_list_page.dart';
import 'pages/admin_product_list_page.dart';
import 'theme/admin_theme.dart';
import 'widgets/admin_ui.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.user,
    required this.onSessionChanged,
    this.authApi,
    this.userAppBuilder,
    this.dashboardPage,
  });

  final AuthUser user;
  final VoidCallback onSessionChanged;
  final AuthApi? authApi;
  final WidgetBuilder? userAppBuilder;
  final Widget? dashboardPage;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const _items = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Tổng quan',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month_rounded),
      label: 'Vận hành',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2_rounded),
      label: 'Quản lý',
    ),
    NavigationDestination(
      icon: Icon(Icons.admin_panel_settings_outlined),
      selectedIcon: Icon(Icons.admin_panel_settings_rounded),
      label: 'Tài khoản',
    ),
  ];

  late final AuthApi _authApi;
  int _currentIndex = 0;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _authApi = widget.authApi ?? AuthApi();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await _authApi.logout();
      if (mounted) widget.onSessionChanged();
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  void _openUserApp() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            widget.userAppBuilder ??
            (_) => MainShell(authApi: _authApi, confirmExitOnBack: false),
      ),
    );
  }

  Future<void> _push(Widget page) {
    return Navigator.of(context)
        .push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  List<_AdminModule> _managementModules() {
    if (widget.user.role.toUpperCase() != 'ADMIN') return const [];
    return [
      _AdminModule(
        icon: Icons.shopping_bag_rounded,
        title: 'Sản phẩm',
        description: 'Sản phẩm, biến thể và sản phẩm nổi bật',
        color: AppColors.primary,
        onOpen: () => _push(const AdminProductListPage(isAdmin: true)),
      ),
      _AdminModule(
        icon: Icons.store_rounded,
        title: 'Chi nhánh và sân',
        description: 'Thông tin chi nhánh, hình ảnh và sân cầu',
        color: AppColors.success,
        onOpen: () => _push(const AdminBranchListPage()),
      ),
      _AdminModule(
        icon: Icons.newspaper_rounded,
        title: 'Nội dung trang chủ',
        description: 'Tin tức, banner và thông báo người dùng',
        color: AppColors.info,
        onOpen: () => _push(AdminContentHubPage(role: widget.user.role)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      widget.dashboardPage ?? const AdminDashboardPage(embedded: true),
      _AdminModuleHub(
        title: 'Vận hành',
        subtitle: 'Theo dõi và xử lý hoạt động hằng ngày',
        modules: [
          _AdminModule(
            icon: Icons.calendar_month_rounded,
            title: 'Lịch đặt sân',
            description: 'Lọc lịch, xem chi tiết và cập nhật trạng thái',
            color: AppColors.info,
            onOpen: () => _push(const AdminBookingListPage()),
          ),
          _AdminModule(
            icon: Icons.receipt_long_rounded,
            title: 'Đơn hàng',
            description: 'Theo dõi đơn giao hàng và nhận tại chi nhánh',
            color: AppColors.primary,
            onOpen: () => _push(const AdminOrderListPage()),
          ),
          _AdminModule(
            icon: Icons.inventory_2_rounded,
            title: 'Tồn kho',
            description: 'Tra cứu số lượng và cảnh báo sắp hết hàng',
            color: AppColors.warning,
            onOpen: () => _push(
              AdminInventoryListPage(
                role: widget.user.role,
                assignedBranchId: widget.user.branchId,
              ),
            ),
          ),
        ],
      ),
      _AdminModuleHub(
        title: 'Quản lý',
        subtitle: 'Cấu hình dữ liệu hiển thị trong ứng dụng',
        modules: _managementModules(),
      ),
      _AdminAccountTab(
        user: widget.user,
        isLoggingOut: _isLoggingOut,
        onOpenUserApp: _openUserApp,
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      backgroundColor: AdminTheme.canvas,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AdminTheme.graphite,
          indicatorColor: AppColors.primary,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : AdminTheme.navigationMuted,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : AdminTheme.navigationMuted,
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            );
          }),
        ),
        child: NavigationBar(
          height: 72,
          selectedIndex: _currentIndex,
          destinations: _items,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
        ),
      ),
    );
  }
}

class _AdminModuleHub extends StatelessWidget {
  const _AdminModuleHub({
    required this.title,
    required this.subtitle,
    required this.modules,
  });

  final String title;
  final String subtitle;
  final List<_AdminModule> modules;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ColoredBox(
        color: AdminTheme.canvas,
        child: Column(
          children: [
            AdminPageHeader(title: title, subtitle: subtitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  if (modules.isEmpty)
                    const _NoPermissionState()
                  else
                    for (final module in modules) ...[
                      _AdminModuleCard(module: module),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminModule {
  const _AdminModule({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onOpen,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onOpen;
}

class _AdminModuleCard extends StatelessWidget {
  const _AdminModuleCard({required this.module});

  final _AdminModule module;

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      onTap: module.onOpen,
      child: Row(
        children: [
          AdminIconBox(icon: module.icon, color: module.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  module.description,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.arrow_forward_rounded,
            size: 20,
            color: AdminTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _NoPermissionState extends StatelessWidget {
  const _NoPermissionState();

  @override
  Widget build(BuildContext context) {
    return const AdminSurface(
      child: AdminStateView(
        icon: Icons.lock_outline_rounded,
        title: 'Không có chức năng quản lý được cấp',
        message: 'Tài khoản hiện tại chỉ có quyền sử dụng các tác vụ vận hành.',
      ),
    );
  }
}

class _AdminAccountTab extends StatelessWidget {
  const _AdminAccountTab({
    required this.user,
    required this.isLoggingOut,
    required this.onOpenUserApp,
    required this.onLogout,
  });

  final AuthUser user;
  final bool isLoggingOut;
  final VoidCallback onOpenUserApp;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ColoredBox(
        color: AdminTheme.canvas,
        child: Column(
          children: [
            const AdminPageHeader(
              title: 'Tài khoản quản trị',
              subtitle: 'Thông tin phiên làm việc và quyền truy cập',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AdminTheme.graphiteSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _roleLabel(user.role),
                                style: const TextStyle(
                                  color: AdminTheme.navigationMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AdminSurface(
                    onTap: onOpenUserApp,
                    child: const Row(
                      children: [
                        AdminIconBox(
                          icon: Icons.phone_android_rounded,
                          color: AdminTheme.info,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xem ứng dụng người dùng',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Mở giao diện khách hàng để kiểm tra',
                                style: TextStyle(
                                  color: AdminTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AdminTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isLoggingOut ? null : onLogout,
                      icon: isLoggingOut
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_rounded),
                      label: const Text('Đăng xuất'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _roleLabel(String role) {
  return switch (role.toUpperCase()) {
    'ADMIN' => 'Quản trị viên',
    'BRANCH_MANAGER' => 'Quản lý chi nhánh',
    'STAFF' => 'Nhân viên',
    _ => role,
  };
}
