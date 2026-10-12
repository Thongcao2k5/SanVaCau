import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';
import 'admin_news_list_page.dart';
import 'admin_banner_list_page.dart';
import 'admin_notification_form_page.dart';

class AdminContentHubPage extends StatelessWidget {
  const AdminContentHubPage({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) => Theme(
    data: AdminTheme.data(Theme.of(context)),
    child: Scaffold(
      appBar: AppBar(title: const Text('Quản lý nội dung')),
      body: SafeArea(
        child: role != 'ADMIN'
            ? const AdminStateView(
                icon: Icons.lock_rounded,
                title: 'Bạn không có quyền truy cập trang này.',
              )
            : ListView(
                padding: const EdgeInsets.all(AdminTheme.pagePadding),
                children: [
                  const Text(
                    'Nội dung trong ứng dụng',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cập nhật thông tin khách hàng nhìn thấy trên trang chủ và trong hộp thư.',
                    style: TextStyle(
                      color: AdminTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _card(
                    context,
                    icon: Icons.article_rounded,
                    title: 'Tin tức',
                    subtitle: 'Bài đã xuất bản xuất hiện ở mục Tin tức và trên trang chủ.',
                    page: AdminNewsListPage(role: role),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    context,
                    icon: Icons.image_rounded,
                    title: 'Banner',
                    subtitle: 'Ảnh quảng bá ở đầu trang chủ, theo thứ tự và lịch hiển thị.',
                    page: AdminBannerListPage(role: role),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    context,
                    icon: Icons.notifications_rounded,
                    title: 'Gửi thông báo',
                    subtitle: 'Gửi nội dung vào hộp thư của một người dùng được chọn.',
                    page: AdminNotificationFormPage(role: role),
                  ),
                  const SizedBox(height: 20),
                  const AdminSurface(
                    child: Text(
                      'Sản phẩm và chi nhánh nổi bật được chọn trong các mục Sản phẩm và Chi nhánh và sân ở tab Quản lý.',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) => AdminSurface(
    onTap: () =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminIconBox(icon: icon, color: AdminTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AdminTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.chevron_right_rounded,
          color: AdminTheme.textSecondary,
        ),
      ],
    ),
  );
}
