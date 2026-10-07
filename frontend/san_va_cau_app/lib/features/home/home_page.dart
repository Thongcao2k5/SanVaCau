import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../search/pages/search_page.dart';
import 'data/home_api.dart';
import 'models/home_data.dart';
import 'widgets/featured_products_section.dart';
import 'widgets/home_hero_section.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/latest_news_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.onBookCourtPressed,
    required this.onViewProductsPressed,
    required this.onViewNewsPressed,
    required this.onViewBranchesPressed,
    required this.onRacketServicePressed,
    super.key,
  });

  final VoidCallback onBookCourtPressed;
  final VoidCallback onViewProductsPressed;
  final VoidCallback onViewNewsPressed;
  final VoidCallback onViewBranchesPressed;
  final VoidCallback onRacketServicePressed;

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
        title: const Text('Sân & Cầu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Tìm kiếm',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<HomeData>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          final banners = snapshot.data?.banners ?? <HomeBanner>[];

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 4),
              // Consolidated hero carousel (API banners + fallback slides).
              HomeHeroSection(
                onBookCourtPressed: widget.onBookCourtPressed,
                onViewProductsPressed: widget.onViewProductsPressed,
                onRacketServicePressed: widget.onRacketServicePressed,
                onViewBranchesPressed: widget.onViewBranchesPressed,
                banners: banners,
              ),
              const SizedBox(height: 20),
              // Quick actions.
              HomeQuickActions(
                onBookCourtPressed: widget.onBookCourtPressed,
                onViewProductsPressed: widget.onViewProductsPressed,
                onRacketServicePressed: widget.onRacketServicePressed,
                onViewBranchesPressed: widget.onViewBranchesPressed,
              ),
              // Data-dependent sections.
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                Padding(
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
                )
              else if (snapshot.hasData) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FeaturedProductsSection(
                    products: snapshot.data!.featuredProducts,
                    onViewAllPressed: widget.onViewProductsPressed,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LatestNewsSection(newsList: snapshot.data!.latestNews),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
