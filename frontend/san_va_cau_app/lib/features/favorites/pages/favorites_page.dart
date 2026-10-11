import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_page_components.dart';
import '../../products/pages/product_detail_page.dart';
import '../data/favorite_api.dart';
import '../models/favorite_item.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({this.favoriteApi, super.key});

  final FavoriteApi? favoriteApi;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late final FavoriteApi _favoriteApi;
  late Future<List<FavoriteItem>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoriteApi = widget.favoriteApi ?? FavoriteApi();
    _favoritesFuture = _favoriteApi.getFavorites();
  }

  void _reloadFavorites() {
    setState(() {
      _favoritesFuture = _favoriteApi.getFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yêu thích của tôi')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              const AppPageIntro(
                icon: Icons.favorite_rounded,
                title: 'Bộ sưu tập của bạn',
                subtitle:
                    'Lưu lại sản phẩm quan tâm để dễ dàng xem và mua sau.',
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<FavoriteItem>>(
                  future: _favoritesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      final error = snapshot.error;
                      final message = error is ApiException
                          ? error.message
                          : 'Không thể tải danh sách yêu thích';

                      return AppStateView(
                        icon: Icons.wifi_off_rounded,
                        title: 'Chưa thể tải yêu thích',
                        message: message,
                        actionLabel: 'Thử lại',
                        onAction: _reloadFavorites,
                      );
                    }

                    final favorites = snapshot.data ?? const <FavoriteItem>[];

                    if (favorites.isEmpty) {
                      return AppStateView(
                        icon: Icons.favorite_border_rounded,
                        title: 'Danh sách đang trống',
                        message: 'Chạm biểu tượng trái tim ở sản phẩm bạn thích để lưu vào đây.',
                        actionLabel: 'Tải lại',
                        onAction: _reloadFavorites,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _reloadFavorites(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 32),
                        itemCount: favorites.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _FavoriteCard(
                          key: ValueKey(favorites[index].id),
                          item: favorites[index],
                          onReload: _reloadFavorites,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.item, required this.onReload, super.key});

  final FavoriteItem item;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final canOpen = item.targetType == 'PRODUCT';
    return Semantics(
      button: canOpen,
      label: 'Mở ${item.targetName}',
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderMuted),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canOpen
              ? () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailPage(productId: item.targetId),
                    ),
                  );
                  onReload();
                }
              : null,
          child: SizedBox(
            height: 124,
            child: Row(
              children: [
                Container(
                  width: 124,
                  color: AppColors.surfaceMuted,
                  padding: const EdgeInsets.all(10),
                  child: AppImage(
                    source: item.targetImageUrl,
                    fit: BoxFit.contain,
                    fallback: const Icon(
                      Icons.image_not_supported_outlined,
                      size: 34,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.targetName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              item.isActive
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.info_outline_rounded,
                              size: 18,
                              color: item.isActive
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.isActive
                                    ? 'Đang kinh doanh'
                                    : 'Ngừng kinh doanh',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: item.isActive
                                          ? AppColors.success
                                          : AppColors.warning,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            if (canOpen)
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
