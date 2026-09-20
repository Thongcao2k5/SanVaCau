import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../products/pages/product_list_page.dart';
import 'data/home_api.dart';
import 'models/home_data.dart';
import 'widgets/featured_products_section.dart';
import 'widgets/home_banner_section.dart';
import 'widgets/home_hero_section.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/latest_news_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<HomeData> _homeDataFuture;
  final HomeApi _homeApi = HomeApi();

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
  }

  void _fetchHomeData() {
    setState(() {
      _homeDataFuture = _homeApi.getHomeData();
      _homeDataFuture.ignore();
    });
  }

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
          FutureBuilder<HomeData>(
            future: _homeDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Column(
                      children: [
                        const Text(
                          'Đã xảy ra lỗi khi tải dữ liệu.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _fetchHomeData,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasData) {
                final data = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeBannerSection(banners: data.banners),
                    FeaturedProductsSection(
                      products: data.featuredProducts,
                      onViewAllPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProductListPage(),
                          ),
                        );
                      },
                    ),
                    LatestNewsSection(newsList: data.latestNews),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
