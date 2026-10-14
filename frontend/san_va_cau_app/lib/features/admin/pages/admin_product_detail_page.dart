import 'package:flutter/material.dart';

import '../../../core/widgets/app_image.dart';

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
          actions: [
            if (widget.isAdmin && _product != null)
              IconButton(
                icon: const Icon(Icons.edit_rounded),
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
                icon: const Icon(Icons.visibility_off_rounded),
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
      return const AdminStateView(
        icon: Icons.inventory_2_rounded,
        title: 'Đang tải chi tiết sản phẩm',
        isLoading: true,
      );
    }

    if (_error != null) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Không thể tải sản phẩm',
        message: _error,
        actionLabel: 'Thử lại',
        onAction: _loadData,
      );
    }

    if (_product == null) {
      return const AdminStateView(
        icon: Icons.search_off_rounded,
        title: 'Không tìm thấy sản phẩm',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AdminTheme.pagePadding,
          16,
          AdminTheme.pagePadding,
          32,
        ),
        children: [
          AdminSurface(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 360 ||
                    MediaQuery.textScalerOf(context).scale(1) >= 1.3;
                final image = ClipRRect(
                  borderRadius: BorderRadius.circular(AdminTheme.compactRadius),
                  child: Container(
                    width: compact ? double.infinity : 104,
                    height: compact ? 170 : 112,
                    color: AdminTheme.canvas,
                    child:
                        _product!.imageUrl != null &&
                            _product!.imageUrl!.isNotEmpty
                        ? AppImage(
                            source: _product!.imageUrl!,
                            fit: BoxFit.cover,
                            fallback: const Icon(
                              Icons.hide_image_rounded,
                              color: AdminTheme.textSecondary,
                              size: 36,
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_rounded,
                            color: AdminTheme.textSecondary,
                            size: 36,
                          ),
                  ),
                );
                final summary = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product!.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AdminTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AdminStatusBadge(
                          label: _product!.isActive
                              ? 'Đang hoạt động'
                              : 'Đã ẩn',
                          tone: _product!.isActive
                              ? AdminStatusTone.success
                              : AdminStatusTone.danger,
                        ),
                        if (_product!.isFeatured)
                          const AdminStatusBadge(
                            label: 'Nổi bật',
                            tone: AdminStatusTone.warning,
                            icon: Icons.star_rounded,
                          ),
                      ],
                    ),
                  ],
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (compact) ...[
                      image,
                      const SizedBox(height: 16),
                      summary,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          image,
                          const SizedBox(width: 16),
                          Expanded(child: summary),
                        ],
                      ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 28,
                      runSpacing: 14,
                      children: [
                        _buildInfoRow(
                          Icons.category_rounded,
                          'Danh mục',
                          _product!.category.name,
                        ),
                        if (_product!.brand != null)
                          _buildInfoRow(
                            Icons.sell_rounded,
                            'Thương hiệu',
                            _product!.brand!.name,
                          ),
                      ],
                    ),
                    if (_product!.description != null &&
                        _product!.description!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Mô tả',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AdminTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _product!.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AdminTheme.textSecondaryStrong,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Variants Section
          Row(
            children: [
              Expanded(
                child: Text(
                  'Phân loại (${_variants.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AdminTheme.textPrimary,
                  ),
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
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Thêm mới'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_variants.isEmpty)
            const AdminSurface(
              child: Row(
                children: [
                  AdminIconBox(
                    icon: Icons.layers_clear_rounded,
                    color: AdminTheme.textSecondaryStrong,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chưa có phân loại nào.',
                      style: TextStyle(color: AdminTheme.textSecondaryStrong),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._variants.map((variant) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminSurface(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AdminTheme.compactRadius,
                        ),
                        child: Container(
                          width: 58,
                          height: 68,
                          color: AdminTheme.canvas,
                          child:
                              variant.imageUrl != null &&
                                  variant.imageUrl!.isNotEmpty
                              ? AppImage(
                                  source: variant.imageUrl!,
                                  fit: BoxFit.cover,
                                  fallback: const Icon(
                                    Icons.hide_image_rounded,
                                    color: AdminTheme.textSecondary,
                                  ),
                                )
                              : const Icon(
                                  Icons.layers_rounded,
                                  color: AdminTheme.textSecondary,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              variant.variantName,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AdminTheme.textPrimary,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU: ${variant.sku}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AdminTheme.textSecondaryStrong,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _formatCurrency(variant.price),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AdminTheme.primaryText,
                                  ),
                                ),
                                AdminStatusBadge(
                                  label: variant.isActive
                                      ? 'Đang hoạt động'
                                      : 'Đã ẩn',
                                  tone: variant.isActive
                                      ? AdminStatusTone.success
                                      : AdminStatusTone.danger,
                                ),
                              ],
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
                                  style: TextStyle(
                                    color: AdminTheme.primaryText,
                                  ),
                                ),
                              ),
                          ],
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

  Widget _buildInfoRow(IconData icon, String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: AdminTheme.primaryText),
      const SizedBox(width: 8),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AdminTheme.textSecondaryStrong,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AdminTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
