import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../products/data/product_api.dart';
import '../../products/models/product.dart';
import '../../products/models/product_variant.dart';
import 'admin_product_form_page.dart';
import 'admin_variant_form_page.dart';

class AdminProductDetailPage extends StatefulWidget {
  const AdminProductDetailPage({
    super.key,
    required this.productId,
    this.isAdmin = false,
    this.productApi,
  });

  final String productId;
  final bool isAdmin;
  final ProductApi? productApi;

  @override
  State<AdminProductDetailPage> createState() => _AdminProductDetailPageState();
}

class _AdminProductDetailPageState extends State<AdminProductDetailPage> {
  late final ProductApi _api;

  bool _isLoading = true;
  String? _error;

  Product? _product;
  List<ProductVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    _api = widget.productApi ?? ProductApi();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getProductById(widget.productId),
        _api.getProductVariants(widget.productId),
      ]);

      if (mounted) {
        setState(() {
          _product = results[0] as Product;
          _variants = results[1] as List<ProductVariant>;
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

  Future<void> _loadVariantsOnly() async {
    try {
      final variants = await _api.getProductVariants(widget.productId);
      if (mounted) {
        setState(() {
          _variants = variants;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách phân loại: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _inactivateProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ẩn sản phẩm'),
        content: const Text(
          'Bạn có chắc chắn muốn ẩn sản phẩm này không? Nó sẽ không hiển thị với khách hàng nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ẩn'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    try {
      await _api.inactivateAdminProduct(widget.productId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ẩn sản phẩm'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Pop back to list and refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _inactivateVariant(ProductVariant variant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ẩn phân loại'),
        content: Text(
          'Bạn có chắc chắn muốn ẩn phân loại "${variant.variantName}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ẩn'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    try {
      await _api.inactivateAdminVariant(variant.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ẩn phân loại'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadVariantsOnly();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  String _formatCurrency(String amountStr) {
    final value = double.tryParse(amountStr) ?? 0.0;
    // Format safely without intl dependency
    final parts = value
        .toStringAsFixed(0)
        .replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');
    return '$parts đ';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        backgroundColor: AdminTheme.canvas,
        appBar: AppBar(
          title: const Text('Chi tiết sản phẩm'),
          backgroundColor: AdminTheme.graphite,
          foregroundColor: Colors.white,
          actions: [
            if (widget.isAdmin && _product != null)
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Sửa',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminProductFormPage(
                        product: _product,
                        productApi: _api,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
              ),
            if (widget.isAdmin && _product != null && _product!.isActive)
              IconButton(
                icon: const Icon(Icons.visibility_off),
                tooltip: 'Ẩn',
                onPressed: _inactivateProduct,
              ),
          ],
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Lỗi: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AdminTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (_product == null) {
      return const Center(child: Text('Không tìm thấy sản phẩm.'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          // Product Info Card
          Card(
            elevation: 0,
            color: AdminTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminTheme.compactRadius),
              side: const BorderSide(color: AdminTheme.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AdminTheme.canvas,
                          borderRadius: BorderRadius.circular(
                            AdminTheme.compactRadius,
                          ),
                        ),
                        child:
                            _product!.imageUrl != null &&
                                _product!.imageUrl!.isNotEmpty
                            ? Image.network(
                                _product!.imageUrl!,
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
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _product!.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AdminTheme.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.category_rounded,
                              'Danh mục:',
                              _product!.category.name,
                            ),
                            const SizedBox(height: 4),
                            if (_product!.brand != null)
                              _buildInfoRow(
                                Icons.branding_watermark_outlined,
                                'Thương hiệu:',
                                _product!.brand!.name,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_product!.isFeatured)
                        const AdminStatusBadge(
                          label: 'Nổi bật',
                          tone: AdminStatusTone.warning,
                        ),
                      AdminStatusBadge(
                        label: _product!.isActive ? 'Đang hoạt động' : 'Đã ẩn',
                        tone: _product!.isActive
                            ? AdminStatusTone.success
                            : AdminStatusTone.danger,
                      ),
                    ],
                  ),
                  if (_product!.description != null &&
                      _product!.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text(
                      'Mô tả:',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _product!.description!,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AdminTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Variants Section
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Phân loại (${_variants.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary,
                ),
              ),
              if (widget.isAdmin)
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminVariantFormPage(
                          productId: _product!.id,
                          productApi: _api,
                        ),
                      ),
                    );
                    if (result != null) {
                      _loadVariantsOnly();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm mới'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_variants.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AdminTheme.surface,
                borderRadius: BorderRadius.circular(AdminTheme.compactRadius),
                border: Border.all(color: AdminTheme.border),
              ),
              child: const Center(
                child: Text(
                  'Chưa có phân loại nào.',
                  style: TextStyle(color: AdminTheme.textSecondary),
                ),
              ),
            )
          else
            ..._variants.map((variant) {
              return Card(
                elevation: 0,
                color: AdminTheme.surface,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.compactRadius),
                  side: const BorderSide(color: AdminTheme.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AdminTheme.canvas,
                          borderRadius: BorderRadius.circular(
                            AdminTheme.compactRadius,
                          ),
                        ),
                        child:
                            variant.imageUrl != null &&
                                variant.imageUrl!.isNotEmpty
                            ? Image.network(
                                variant.imageUrl!,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              variant.variantName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SKU: ${variant.sku}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AdminTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatCurrency(variant.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.isAdmin)
                        PopupMenuButton<String>(
                          tooltip: 'Thao tác phân loại',
                          icon: const Icon(
                            Icons.more_vert,
                            color: AdminTheme.textSecondary,
                          ),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminVariantFormPage(
                                    productId: _product!.id,
                                    variant: variant,
                                    productApi: _api,
                                  ),
                                ),
                              );
                              if (result != null) {
                                _loadVariantsOnly();
                              }
                            } else if (value == 'inactivate') {
                              _inactivateVariant(variant);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Sửa'),
                            ),
                            if (variant.isActive)
                              const PopupMenuItem(
                                value: 'inactivate',
                                child: Text(
                                  'Ẩn phân loại',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                          ],
                        )
                      else if (!variant.isActive)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Đã ẩn',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AdminTheme.textPrimary,
        ),
      ),
    ],
  );
}
