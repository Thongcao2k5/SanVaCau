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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderMuted),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _QuickActionTile(
            icon: Icons.sports_tennis_outlined,
            title: 'Đặt sân',
            color: AppColors.primary,
            backgroundColor: AppColors.primarySoft,
            onTap: onBookCourtPressed,
          ),
          _QuickActionTile(
            icon: Icons.shopping_bag_outlined,
            title: 'Sản phẩm',
            color: AppColors.warning,
            backgroundColor: AppColors.warningSoft,
            onTap: onViewProductsPressed,
          ),
          _QuickActionTile(
            icon: Icons.article_outlined,
            title: 'Tin tức',
            color: AppColors.info,
            backgroundColor: AppColors.infoSoft,
            onTap: onViewNewsPressed,
          ),
          _QuickActionTile(
            icon: Icons.storefront_outlined,
            title: 'Chi nhánh',
            color: AppColors.success,
            backgroundColor: AppColors.successSoft,
            onTap: onViewBranchesPressed,
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
