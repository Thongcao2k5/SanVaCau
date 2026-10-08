import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../branches/models/branch.dart';
import '../branches/pages/branch_detail_page.dart';
import '../search/pages/search_page.dart';
import 'data/home_api.dart';
import 'models/home_data.dart';
import 'widgets/featured_products_section.dart';
import 'widgets/featured_branches_section.dart';
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
    required this.onBookBranchPressed,
    super.key,
  });

  final VoidCallback onBookCourtPressed;
  final VoidCallback onViewProductsPressed;
  final VoidCallback onViewNewsPressed;
  final VoidCallback onViewBranchesPressed;
  final VoidCallback onRacketServicePressed;
  final ValueChanged<Branch> onBookBranchPressed;

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Sân & Cầu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            shadows: [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        actions: [
          IconButton.filled(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Tìm kiếm',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.94),
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size(42, 42),
              maximumSize: const Size(42, 42),
            ),
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
              // Consolidated hero carousel (API banners + fallback slides).
              HomeHeroSection(
                onBookCourtPressed: widget.onBookCourtPressed,
                onViewProductsPressed: widget.onViewProductsPressed,
                onRacketServicePressed: widget.onRacketServicePressed,
                onViewBranchesPressed: widget.onViewBranchesPressed,
                banners: banners,
              ),
              const SizedBox(height: 8),
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
                  child: FeaturedBranchesSection(
                    branches: snapshot.data!.branches
                        .map(
                          (branch) => Branch(
                            id: branch.id,
                            name: branch.name,
                            address: branch.address,
                            phone: branch.phone,
                            openingTime: branch.openingTime,
                            closingTime: branch.closingTime,
                            status: branch.status,
                            description: branch.description,
                            imageUrl: branch.imageUrl,
                            isFeatured: branch.isFeatured,
                            sortOrder: branch.sortOrder,
                          ),
                        )
                        .toList(),
                    onViewAllPressed: widget.onViewBranchesPressed,
                    onBranchPressed: (branch) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (detailContext) => BranchDetailPage(
                            branch: branch,
                            onBookPressed: () {
                              Navigator.of(detailContext).pop();
                              widget.onBookBranchPressed(branch);
                            },
                          ),
                        ),
                      );
                    },
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
