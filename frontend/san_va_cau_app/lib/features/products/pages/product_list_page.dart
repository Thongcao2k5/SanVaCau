import '../../cart/widgets/cart_badge.dart';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../cart/data/cart_api.dart';
import '../../cart/pages/cart_page.dart';
import '../data/product_api.dart';
import '../models/product.dart';
import 'product_detail_page.dart';
import '../widgets/product_card.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key, this.productApi, this.cartApi});

  final ProductApi? productApi;
  final CartApi? cartApi;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late final ProductApi _productApi;
  late final CartApi _cartApi;
  late Future<List<Product>> _productsFuture;

  final _searchController = TextEditingController();
  String _query = "";

  String? _categoryId;
  String? _categoryName;

  bool get _hasFilters => _categoryId != null || _query.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _productApi = widget.productApi ?? ProductApi();
    _cartApi = widget.cartApi ?? CartApi();
    _productsFuture = _productApi.getProducts();
  }

  Future<void> _reloadProducts() async {
    final future = _productApi.getProducts(categoryId: _categoryId);
    setState(() {
      _productsFuture = future;
    });
    await future;
  }

  void _clearFilters() {
    setState(() {
      _categoryId = null;
      _categoryName = null;
      _query = "";
      _searchController.clear();
    });
    _reloadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _productTile(Product product) => ProductCard(
    key: ValueKey(product.id),
    product: product,
    productApi: _productApi,
    cartApi: _cartApi,
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProductDetailPage(productId: product.id, initialProduct: product),
      ),
    ),
  );

  Widget _buildCatalog(List<Product> products) {
    final groups = <String, List<Product>>{};
    for (final product in products) {
      groups.putIfAbsent(product.categoryId, () => []).add(product);
    }
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        for (final entry in groups.entries) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.value.first.category.name.isEmpty
                          ? 'Sản phẩm khác'
                          : entry.value.first.category.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_categoryId == null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _categoryId = entry.key;
                          _categoryName = entry.value.first.category.name;
                        });
                        _reloadProducts();
                      },
                      child: const Text('Xem thêm'),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.55,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _productTile(entry.value[index]),
                childCount: _categoryId == null && _query.isEmpty
                    ? entry.value.length.clamp(0, 4)
                    : entry.value.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 89)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 76,
        title: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value.trim()),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Giỏ hàng',
            color: Colors.white,
            icon: const CartBadge(),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CartPage(cartApi: _cartApi),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final error = snapshot.error;
                  final message = error is ApiException
                      ? error.message
                      : 'Không thể tải danh sách sản phẩm';

                  return _ProductStateMessage(
                    icon: Icons.wifi_off_outlined,
                    title: 'Có lỗi xảy ra',
                    message: message,
                    actionText: 'Thử lại',
                    onActionPressed: _reloadProducts,
                  );
                }

                final products = (snapshot.data ?? const <Product>[]).where((
                  product,
                ) {
                  final query = _query.toLowerCase();
                  return product.name.toLowerCase().contains(query) ||
                      (product.brand?.name.toLowerCase().contains(query) ??
                          false) ||
                      product.category.name.toLowerCase().contains(query);
                }).toList();

                final headerTitle = _categoryName ?? 'Tất cả sản phẩm';
                final headerCount = '${products.length} sản phẩm';

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_categoryId != null)
                            IconButton(
                              tooltip: 'Tất cả sản phẩm',
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.arrow_back),
                            ),
                          Expanded(
                            child: Text(
                              headerTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            headerCount,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: products.isEmpty
                          ? _ProductStateMessage(
                              icon: Icons.inventory_2_outlined,
                              title: _hasFilters
                                  ? 'Không tìm thấy sản phẩm'
                                  : 'Chưa có sản phẩm',
                              message: _hasFilters
                                  ? 'Thử từ khóa khác hoặc quay lại tất cả sản phẩm.'
                                  : 'Khi admin thêm sản phẩm, danh sách sẽ hiển thị ở đây.',
                              actionText: _hasFilters
                                  ? 'Xem tất cả sản phẩm'
                                  : 'Tải lại',
                              onActionPressed: _hasFilters
                                  ? _clearFilters
                                  : _reloadProducts,
                            )
                          : RefreshIndicator(
                              onRefresh: _reloadProducts,
                              child: _buildCatalog(products),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductStateMessage extends StatelessWidget {
  const _ProductStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onActionPressed, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}
