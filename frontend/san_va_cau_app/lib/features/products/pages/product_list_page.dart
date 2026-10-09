import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../cart/data/cart_api.dart';
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
  late Future<_FilterData> _filterDataFuture;

  String? _categoryId;
  String? _categoryName;
  String? _brandId;

  bool get _hasFilters => _categoryId != null || _brandId != null;

  @override
  void initState() {
    super.initState();
    _productApi = widget.productApi ?? ProductApi();
    _cartApi = widget.cartApi ?? CartApi();
    _filterDataFuture = _loadFilterData();
    _productsFuture = _productApi.getProducts();
  }

  Future<_FilterData> _loadFilterData() async {
    final results = await Future.wait([
      _productApi.getCategories(),
      _productApi.getBrands(),
    ]);
    return _FilterData(
      categories: results[0] as List<ProductCategory>,
      brands: results[1] as List<ProductBrand>,
    );
  }

  void _retryFilterData() {
    setState(() {
      _filterDataFuture = _loadFilterData();
    });
  }

  Future<void> _reloadProducts() async {
    final future = _productApi.getProducts(
      categoryId: _categoryId,
      brandId: _brandId,
    );
    setState(() {
      _productsFuture = future;
    });
    await future;
  }

  void _clearFilters() {
    setState(() {
      _categoryId = null;
      _categoryName = null;
      _brandId = null;
    });
    _reloadProducts();
  }

  Widget _buildCategorySelector(List<ProductCategory> categories) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text('Tất cả'),
              selected: _categoryId == null,
              onSelected: (selected) {
                if (selected && _categoryId != null) {
                  setState(() {
                    _categoryId = null;
                    _categoryName = null;
                  });
                  _reloadProducts();
                }
              },
            );
          }
          final category = categories[index - 1];
          return ChoiceChip(
            label: Text(category.name),
            selected: _categoryId == category.id,
            onSelected: (selected) {
              if (selected && _categoryId != category.id) {
                setState(() {
                  _categoryId = category.id;
                  _categoryName = category.name;
                });
                _reloadProducts();
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildBrandSelector(List<ProductBrand> brands) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: brands.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text('Tất cả hãng'),
              selected: _brandId == null,
              onSelected: (selected) {
                if (selected && _brandId != null) {
                  setState(() {
                    _brandId = null;
                  });
                  _reloadProducts();
                }
              },
            );
          }
          final brand = brands[index - 1];
          return ChoiceChip(
            label: Text(brand.name),
            selected: _brandId == brand.id,
            onSelected: (selected) {
              if (selected && _brandId != brand.id) {
                setState(() {
                  _brandId = brand.id;
                });
                _reloadProducts();
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm')),
      body: Column(
        children: [
          FutureBuilder<_FilterData>(
            future: _filterDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 56,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Chưa thể tải bộ lọc',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _retryFilterData,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) return const SizedBox.shrink();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  _buildCategorySelector(snapshot.data!.categories),
                  const SizedBox(height: 8),
                  _buildBrandSelector(snapshot.data!.brands),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
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

                final products = snapshot.data ?? const <Product>[];

                final headerTitle = _categoryName ?? 'Tất cả sản phẩm';
                final headerCount = '${products.length} sản phẩm';

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                                  ? 'Thử thay đổi hoặc xóa bộ lọc hiện tại.'
                                  : 'Khi admin thêm sản phẩm, danh sách sẽ hiển thị ở đây.',
                              actionText: _hasFilters
                                  ? 'Xóa bộ lọc'
                                  : 'Tải lại',
                              onActionPressed: _hasFilters
                                  ? _clearFilters
                                  : _reloadProducts,
                            )
                          : RefreshIndicator(
                              onRefresh: _reloadProducts,
                              child: GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  89,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 0.65,
                                    ),
                                itemCount: products.length,
                                itemBuilder: (context, index) {
                                  final product = products[index];

                                  return ProductCard(
                                    key: ValueKey(product.id),
                                    product: product,
                                    productApi: _productApi,
                                    cartApi: _cartApi,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ProductDetailPage(
                                            productId: product.id,
                                            initialProduct: product,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
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

class _FilterData {
  const _FilterData({required this.categories, required this.brands});

  final List<ProductCategory> categories;
  final List<ProductBrand> brands;
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
      child: Padding(
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
