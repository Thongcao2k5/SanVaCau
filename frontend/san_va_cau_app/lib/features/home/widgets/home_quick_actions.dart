import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({
    required this.onBookCourtPressed,
    required this.onViewProductsPressed,
    required this.onViewNewsPressed,
    required this.onViewBranchesPressed,
    super.key,
  });

  final VoidCallback onBookCourtPressed;
  final VoidCallback onViewProductsPressed;
  final VoidCallback onViewNewsPressed;
  final VoidCallback onViewBranchesPressed;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.42,
      ),
      children: [
        _QuickActionTile(
          icon: Icons.sports_tennis_outlined,
          title: 'Đặt sân',
          description: 'Tìm sân và đặt lịch',
          color: const Color(0xFF16A34A),
          onTap: onBookCourtPressed,
        ),
        _QuickActionTile(
          icon: Icons.shopping_bag_outlined,
          title: 'Sản phẩm',
          description: 'Vợt, giày, phụ kiện',
          color: AppColors.primary,
          onTap: onViewProductsPressed,
        ),
        _QuickActionTile(
          icon: Icons.article_outlined,
          title: 'Tin tức',
          description: 'Sân mới, mẹo cầu lông',
          color: const Color(0xFF2563EB),
          onTap: onViewNewsPressed,
        ),
        _QuickActionTile(
          icon: Icons.storefront_outlined,
          title: 'Chi nhánh',
          description: 'Cơ sở và giờ mở cửa',
          color: const Color(0xFF7C3AED),
          onTap: onViewBranchesPressed,
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
