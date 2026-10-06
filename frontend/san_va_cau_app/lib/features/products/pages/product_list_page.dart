import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/product_api.dart';
import '../models/product.dart';
import 'product_detail_page.dart';
import '../widgets/product_card.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key, this.productApi});

  final ProductApi? productApi;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late final ProductApi _productApi;
  late Future<List<Product>> _productsFuture;
  String? _categoryId;
  String? _categoryName;
  String? _brandId;
  String? _brandName;

  bool get _hasFilters => _categoryId != null || _brandId != null;

  @override
  void initState() {
    super.initState();
    _productApi = widget.productApi ?? ProductApi();
    _productsFuture = _productApi.getProducts();
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

  Future<void> _openFilters() async {
    final selection = await showModalBottomSheet<_ProductFilterSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProductFilterSheet(
        productApi: _productApi,
        categoryId: _categoryId,
        brandId: _brandId,
      ),
    );
    if (selection == null || !mounted) return;

    _categoryId = selection.categoryId;
    _categoryName = selection.categoryName;
    _brandId = selection.brandId;
    _brandName = selection.brandName;
    await _reloadProducts();
  }

  Future<void> _clearFilters() async {
    _categoryId = null;
    _categoryName = null;
    _brandId = null;
    _brandName = null;
    await _reloadProducts();
  }

  String get _filterSummary {
    return [_categoryName, _brandName].whereType<String>().join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm'),
        actions: [
          Badge(
            isLabelVisible: _hasFilters,
            child: IconButton(
              tooltip: 'Lọc sản phẩm',
              onPressed: _openFilters,
              icon: const Icon(Icons.filter_list),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_hasFilters)
            Material(
              color: AppColors.surfaceMuted,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_alt_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _filterSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Xóa bộ lọc',
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
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

                if (products.isEmpty) {
                  return _ProductStateMessage(
                    icon: Icons.inventory_2_outlined,
                    title: _hasFilters
                        ? 'Không tìm thấy sản phẩm'
                        : 'Chưa có sản phẩm',
                    message: _hasFilters
                        ? 'Thử thay đổi hoặc xóa bộ lọc hiện tại.'
                        : 'Khi admin thêm sản phẩm, danh sách sẽ hiển thị ở đây.',
                    actionText: _hasFilters ? 'Xóa bộ lọc' : 'Tải lại',
                    onActionPressed: _hasFilters
                        ? _clearFilters
                        : _reloadProducts,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _reloadProducts,
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];

                      return ProductCard(
                        key: ValueKey(product.id),
                        product: product,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductFilterSheet extends StatefulWidget {
  const _ProductFilterSheet({
    required this.productApi,
    this.categoryId,
    this.brandId,
  });

  final ProductApi productApi;
  final String? categoryId;
  final String? brandId;

  @override
  State<_ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<_ProductFilterSheet> {
  late Future<_ProductFilterData> _filterDataFuture;
  String? _categoryId;
  String? _brandId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId;
    _brandId = widget.brandId;
    _filterDataFuture = _loadFilterData();
  }

  Future<_ProductFilterData> _loadFilterData() async {
    final categoriesFuture = widget.productApi.getCategories();
    final brandsFuture = widget.productApi.getBrands();
    return _ProductFilterData(
      categories: await categoriesFuture,
      brands: await brandsFuture,
    );
  }

  void _retry() {
    setState(() {
      _filterDataFuture = _loadFilterData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_ProductFilterData>(
        future: _filterDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 280,
              child: _ProductStateMessage(
                icon: Icons.wifi_off_outlined,
                title: 'Chưa thể tải bộ lọc',
                message: 'Vui lòng kiểm tra kết nối và thử lại.',
                actionText: 'Thử lại',
                onActionPressed: _retry,
              ),
            );
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bộ lọc sản phẩm',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Danh mục',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.categories
                      .map(
                        (category) => ChoiceChip(
                          label: Text(category.name),
                          selected: _categoryId == category.id,
                          onSelected: (selected) => setState(
                            () => _categoryId = selected ? category.id : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Thương hiệu',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.brands
                      .map(
                        (brand) => ChoiceChip(
                          label: Text(brand.name),
                          selected: _brandId == brand.id,
                          onSelected: (selected) => setState(
                            () => _brandId = selected ? brand.id : null,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _categoryId = null;
                          _brandId = null;
                        }),
                        child: const Text('Đặt lại'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final category = data.categories
                              .where((item) => item.id == _categoryId)
                              .firstOrNull;
                          final brand = data.brands
                              .where((item) => item.id == _brandId)
                              .firstOrNull;
                          Navigator.of(context).pop(
                            _ProductFilterSelection(
                              categoryId: category?.id,
                              categoryName: category?.name,
                              brandId: brand?.id,
                              brandName: brand?.name,
                            ),
                          );
                        },
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductFilterData {
  const _ProductFilterData({required this.categories, required this.brands});

  final List<ProductCategory> categories;
  final List<ProductBrand> brands;
}

class _ProductFilterSelection {
  const _ProductFilterSelection({
    this.categoryId,
    this.categoryName,
    this.brandId,
    this.brandName,
  });

  final String? categoryId;
  final String? categoryName;
  final String? brandId;
  final String? brandName;
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
