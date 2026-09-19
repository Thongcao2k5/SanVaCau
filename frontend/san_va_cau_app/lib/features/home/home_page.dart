import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../products/pages/product_list_page.dart';
import 'widgets/home_hero_section.dart';
import 'widgets/home_quick_actions.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SanVaCau')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HomeHeroSection(
            onBookCourtPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phần đặt sân sẽ được làm ở bước sau.'),
                ),
              );
            },
            onViewProductsPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProductListPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Khám phá nhanh',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          HomeQuickActions(
            onBookCourtPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phần đặt sân sẽ được làm ở bước sau.'),
                ),
              );
            },
            onViewProductsPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProductListPage(),
                ),
              );
            },
            onViewNewsPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phần tin tức sẽ được làm sau News API.'),
                ),
              );
            },
            onViewBranchesPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phần chi nhánh sẽ được làm ở bước sau.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
