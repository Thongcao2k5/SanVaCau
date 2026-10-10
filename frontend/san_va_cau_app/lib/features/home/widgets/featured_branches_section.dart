import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../branches/models/branch.dart';

class FeaturedBranchesSection extends StatelessWidget {
  const FeaturedBranchesSection({
    super.key,
    required this.branches,
    required this.onBranchPressed,
    required this.onViewAllPressed,
  });

  final List<Branch> branches;
  final ValueChanged<Branch> onBranchPressed;
  final VoidCallback onViewAllPressed;

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chi nhánh nổi bật',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: onViewAllPressed,
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...branches
            .take(2)
            .map(
              (branch) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onBranchPressed(branch),
                    child: SizedBox(
                      height: 104,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 112,
                            height: double.infinity,
                            child: AppImage(
                              source: branch.imageUrl ?? '',
                              fit: BoxFit.contain,
                              fallback: const Icon(
                                Icons.storefront_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    branch.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    branch.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          height: 1.3,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${_shortTime(branch.openingTime)} - ${_shortTime(branch.closingTime)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  String _shortTime(String value) {
    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}
