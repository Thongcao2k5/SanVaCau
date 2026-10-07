import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _api = widget.productApi ?? ProductApi();
    _loadInitialData();
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
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm'),
        centerTitle: true,
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Lỗi: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy sản phẩm nào.',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16).copyWith(bottom: 80),
        itemCount: _products.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final product = _products[index];
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
              if (result == true) {
                _loadProducts();
              }
            },
          );
        },
      ),
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
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
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
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        color: AppColors.textSecondary,
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
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category.name}${product.brand != null ? ' • ${product.brand!.name}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (product.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'Nổi bật',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        if (!product.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'Đã ẩn',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
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
