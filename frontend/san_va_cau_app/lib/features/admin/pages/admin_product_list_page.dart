import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import '../../../core/theme/app_colors.dart';
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
      backgroundColor: AdminTheme.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bộ lọc',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        key: const Key('admin-product-category-filter'),
                        initialValue: _selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                          border: OutlineInputBorder(),
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
                          border: OutlineInputBorder(),
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
                          const SizedBox(width: 16),
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
          backgroundColor: AdminTheme.graphite,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
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
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                child: const Icon(Icons.add),
              )
            : null,
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_rounded,
              size: 64,
              color: AdminTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy sản phẩm nào.',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AdminTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    final visibleProducts = _visibleProducts;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
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
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilterChip(
              label: const Text('Chỉ sản phẩm nổi bật'),
              avatar: const Icon(Icons.star_rounded, size: 18),
              selected: _featuredOnly,
              onSelected: (value) => setState(() => _featuredOnly = value),
            ),
          ),
        ),
        if (_selectedCategoryId != null || _selectedBrandId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedCategoryId != null)
                  InputChip(
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
                    label: Text(
                      _brands.firstWhere((b) => b.id == _selectedBrandId).name,
                    ),
                    onDeleted: () {
                      setState(() => _selectedBrandId = null);
                      _loadProducts();
                    },
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: visibleProducts.isEmpty
              ? const AdminStateView(
                  icon: Icons.search_off_rounded,
                  title: 'Không có sản phẩm phù hợp',
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16).copyWith(bottom: 80),
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
    return Card(
      elevation: 0,
      color: AdminTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTheme.compactRadius),
        side: const BorderSide(color: AdminTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AdminTheme.canvas,
                  borderRadius: BorderRadius.circular(AdminTheme.compactRadius),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.image_not_supported_rounded,
                          color: AdminTheme.textSecondary,
                        ),
                      )
                    : const Icon(
                        Icons.image_rounded,
                        color: AdminTheme.textSecondary,
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AdminTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category.name}${product.brand != null ? ' • ${product.brand!.name}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AdminTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (product.isFeatured)
                          const AdminStatusBadge(
                            label: 'Nổi bật',
                            tone: AdminStatusTone.warning,
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
      ),
    );
  }
}
