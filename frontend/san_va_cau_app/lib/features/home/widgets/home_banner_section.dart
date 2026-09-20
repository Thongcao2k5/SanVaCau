import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/home_data.dart';

class HomeBannerSection extends StatelessWidget {
  const HomeBannerSection({super.key, required this.banners});

  final List<HomeBanner> banners;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final banner = banners.first;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Card(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (banner.imageUrl.isNotEmpty)
              Image.network(
                banner.imageUrl,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 160,
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: AppColors.textSecondary,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
            if (banner.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  banner.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
