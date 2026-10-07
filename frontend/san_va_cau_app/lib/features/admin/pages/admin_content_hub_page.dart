import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'admin_news_list_page.dart';
import 'admin_banner_list_page.dart';
import 'admin_notification_form_page.dart';

class AdminContentHubPage extends StatelessWidget {
  const AdminContentHubPage({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    if (role != 'ADMIN') {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý nội dung')),
        body: const Center(
          child: Text('Bạn không có quyền truy cập trang này.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý nội dung'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            context,
            icon: Icons.article,
            title: 'Tin tức',
            subtitle: 'Quản lý tin tức, bài viết',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminNewsListPage(role: role),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            icon: Icons.image,
            title: 'Banner',
            subtitle: 'Quản lý banner nổi bật',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminBannerListPage(role: role),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            context,
            icon: Icons.notifications,
            title: 'Gửi thông báo',
            subtitle: 'Gửi thông báo đến người dùng',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminNotificationFormPage(role: role),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
