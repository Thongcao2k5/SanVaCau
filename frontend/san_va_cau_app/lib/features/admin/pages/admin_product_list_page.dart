import 'package:flutter/material.dart';

import '../../../core/widgets/app_image.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import '../../products/data/product_api.dart';
import '../../products/models/product.dart';
import 'admin_product_detail_page.dart';
import 'admin_product_form_page.dart';

class AdminProductListPage extends StatefulWidget {
  const AdminProductListPage({
    super.key,
    this.productApi,
    this.isAdmin = false,
  });

  final ProductApi? productApi;
  final bool isAdmin;

  @override
  State<AdminProductListPage> createState() => _AdminProductListPageState();
}

class _AdminProductListPageState extends State<AdminProductListPage> {
  late final ProductApi _api;

  bool _isLoading = true;
  String? _error;
  List<Product> _products = [];

  List<ProductCategory> _categories = [];
  List<ProductBrand> _brands = [];

  String? _selectedCategoryId;
  String? _selectedBrandId;
  final TextEditingController _searchController = TextEditingController();
  bool _featuredOnly = false;

  @override
  void initState() {
    super.initState();
    _api = widget.productApi ?? ProductApi();
    _searchController.addListener(_applyLocalFilters);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyLocalFilters() => setState(() {});

  List<Product> get _visibleProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _products.where((product) {
      if (_featuredOnly && !product.isFeatured) return false;
      if (query.isEmpty) return true;
      return product.name.toLowerCase().contains(query) ||
          product.category.name.toLowerCase().contains(query) ||
          (product.brand?.name.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getCategories(),
        _api.getBrands(),
        _api.getProducts(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<ProductCategory>;
          _brands = results[1] as List<ProductBrand>;
          _products = results[2] as List<Product>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _api.getProducts(
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AdminTheme.pagePadding,
                    12,
                    AdminTheme.pagePadding,
                    20 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AdminTheme.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const AdminIconBox(
                            icon: Icons.tune_rounded,
                            color: AdminTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bộ lọc sản phẩm',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AdminTheme.textPrimary,
                                      ),
                                ),
                                Text(
                                  'Thu hẹp danh sách theo danh mục và thương hiệu',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AdminTheme.textSecondaryStrong,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        key: const Key('admin-product-category-filter'),
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Tất cả danh mục'),
                          ),
                          ..._categories.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setSheetState(() => _selectedCategoryId = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        key: const Key('admin-product-brand-filter'),
                        initialValue: _selectedBrandId,
                        decoration: const InputDecoration(
                          labelText: 'Thương hiệu',
                          prefixIcon: Icon(Icons.sell_rounded),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Tất cả thương hiệu'),
                          ),
                          ..._brands.map(
                            (b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setSheetState(() => _selectedBrandId = val);
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setSheetState(() {
                                  _selectedCategoryId = null;
                                  _selectedBrandId = null;
                                });
                                Navigator.pop(context);
                                _loadProducts();
                              },
                              child: const Text('Xóa bộ lọc'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _loadProducts();
                              },
                              child: const Text('Áp dụng'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        backgroundColor: AdminTheme.canvas,
        appBar: AppBar(
          title: const Text('Quản lý sản phẩm'),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: _showFilterSheet,
              tooltip: 'Lọc',
            ),
          ],
        ),
        floatingActionButton: widget.isAdmin
            ? FloatingActionButton(
                tooltip: 'Thêm sản phẩm',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminProductFormPage(productApi: _api),
                    ),
                  );
                  if (result == true) {
                    _loadProducts();
                  }
                },
                backgroundColor: AdminTheme.primary,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add_rounded),
              )
            : null,
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _products.isEmpty) {
      return const AdminStateView(
        icon: Icons.inventory_2_rounded,
        title: 'Đang tải sản phẩm',
        isLoading: true,
      );
    }

    if (_error != null && _products.isEmpty) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Lỗi: $_error',
        actionLabel: 'Thử lại',
        onAction: _loadInitialData,
      );
    }

    if (_products.isEmpty) {
      return const AdminStateView(
        icon: Icons.inventory_2_rounded,
        title: 'Chưa có sản phẩm',
        message: 'Sản phẩm mới sẽ xuất hiện tại đây.',
      );
    }

    final visibleProducts = _visibleProducts;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AdminTheme.pagePadding,
            16,
            AdminTheme.pagePadding,
            10,
          ),
          child: AdminSurface(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm sản phẩm, danh mục, thương hiệu',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Xóa tìm kiếm',
                            onPressed: _searchController.clear,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Sản phẩm nổi bật'),
                      avatar: Icon(
                        _featuredOnly
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 18,
                      ),
                      selected: _featuredOnly,
                      onSelected: (value) =>
                          setState(() => _featuredOnly = value),
                    ),
                    if (_selectedCategoryId != null)
                      InputChip(
                        avatar: const Icon(Icons.category_rounded, size: 18),
                        label: Text(
                          _categories
                              .firstWhere((c) => c.id == _selectedCategoryId)
                              .name,
                        ),
                        onDeleted: () {
                          setState(() => _selectedCategoryId = null);
                          _loadProducts();
                        },
                      ),
                    if (_selectedBrandId != null)
                      InputChip(
                        avatar: const Icon(Icons.sell_rounded, size: 18),
                        label: Text(
                          _brands
                              .firstWhere((b) => b.id == _selectedBrandId)
                              .name,
                        ),
                        onDeleted: () {
                          setState(() => _selectedBrandId = null);
                          _loadProducts();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AdminTheme.pagePadding,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${visibleProducts.length} sản phẩm',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AdminTheme.textSecondaryStrong,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showFilterSheet,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Bộ lọc'),
              ),
            ],
          ),
        ),
        Expanded(
          child: visibleProducts.isEmpty
              ? const AdminStateView(
                  icon: Icons.search_off_rounded,
                  title: 'Không có sản phẩm phù hợp',
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: AdminTheme.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AdminTheme.pagePadding,
                      8,
                      AdminTheme.pagePadding,
                      96,
                    ),
                    itemCount: visibleProducts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = visibleProducts[index];
                      return _ProductCard(
                        product: product,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminProductDetailPage(
                                productId: product.id,
                                isAdmin: widget.isAdmin,
                                productApi: _api,
                              ),
                            ),
                          );
                          if (result == true) _loadProducts();
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Xem chi tiết ${product.name}',
      child: AdminSurface(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AdminTheme.compactRadius),
              child: Container(
                width: 76,
                height: 88,
                color: AdminTheme.canvas,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? AppImage(
                        source: product.imageUrl!,
                        fit: BoxFit.cover,
                        fallback: const Icon(
                          Icons.hide_image_rounded,
                          color: AdminTheme.textSecondary,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_rounded,
                        color: AdminTheme.textSecondary,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AdminTheme.textPrimary,
                                height: 1.25,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AdminTheme.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${product.category.name}${product.brand != null ? ' • ${product.brand!.name}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminTheme.textSecondaryStrong,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (product.isFeatured)
                        const AdminStatusBadge(
                          label: 'Nổi bật',
                          tone: AdminStatusTone.warning,
                          icon: Icons.star_rounded,
                        ),
                      AdminStatusBadge(
                        label: product.isActive ? 'Đang hoạt động' : 'Đã ẩn',
                        tone: product.isActive
                            ? AdminStatusTone.success
                            : AdminStatusTone.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
