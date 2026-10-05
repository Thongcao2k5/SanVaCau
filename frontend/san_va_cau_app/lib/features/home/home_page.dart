import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../search/pages/search_page.dart';
import 'data/home_api.dart';
import 'models/home_data.dart';
import 'widgets/featured_products_section.dart';
import 'widgets/home_banner_section.dart';
import 'widgets/home_hero_section.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/latest_news_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({
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
      appBar: AppBar(
        title: const Text('SanVaCau'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HomeHeroSection(
            onBookCourtPressed: widget.onBookCourtPressed,
            onViewProductsPressed: widget.onViewProductsPressed,
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
            onBookCourtPressed: widget.onBookCourtPressed,
            onViewProductsPressed: widget.onViewProductsPressed,
            onViewNewsPressed: widget.onViewNewsPressed,
            onViewBranchesPressed: widget.onViewBranchesPressed,
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
                      onViewAllPressed: widget.onViewProductsPressed,
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
