import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../cart/data/cart_api.dart';
import '../../favorites/data/favorite_api.dart';
import '../../reviews/widgets/reviews_section.dart';
import '../data/product_api.dart';
import '../models/product.dart';
import '../models/product_variant.dart';

class _ProductDetailData {
  _ProductDetailData(this.product, this.variants);
  final Product product;
  final List<ProductVariant> variants;
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    required this.productId,
    this.initialProduct,
    super.key,
  });

  final String productId;
  final Product? initialProduct;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductApi _productApi;
  late final FavoriteApi _favoriteApi;
  late Future<_ProductDetailData> _dataFuture;
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _isFavorited = false;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _productApi = ProductApi();
    _favoriteApi = FavoriteApi();
    _dataFuture = _loadData();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final isFav = await _favoriteApi.checkFavorite(
        'PRODUCT',
        widget.productId,
      );
      if (mounted) {
        setState(() {
          _isFavorited = isFav;
        });
      }
    } catch (_) {
      // Ignore 401 unauthenticated
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;

    setState(() {
      _isTogglingFavorite = true;
    });

    try {
      if (_isFavorited) {
        await _favoriteApi.removeFavorite('PRODUCT', widget.productId);
      } else {
        await _favoriteApi.addFavorite('PRODUCT', widget.productId);
      }

      if (mounted) {
        setState(() {
          _isFavorited = !_isFavorited;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
    }
  }

  Future<_ProductDetailData> _loadData() async {
    final product = await _productApi.getProductById(widget.productId);
    final variants = await _productApi.getProductVariants(widget.productId);
    return _ProductDetailData(product, variants);
  }

  void _reloadProduct() {
    setState(() {
      _dataFuture = _loadData();
      _selectedVariant = null;
      _quantity = 1;
    });
  }

  Future<void> _addToCart() async {
    if (_selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn phân loại sản phẩm')),
      );
      return;
    }

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final cartApi = CartApi();
      await cartApi.addItem(
        productVariantId: _selectedVariant!.id,
        quantity: _quantity,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 401) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  Widget _buildVariantsSection(List<ProductVariant> variants) {
    if (variants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Phân loại',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: variants.map((variant) {
            final isSelected = _selectedVariant?.id == variant.id;
            return ChoiceChip(
              label: Text(variant.variantName),
              selected: isSelected,
              onSelected: variant.isActive
                  ? (selected) {
                      setState(() {
                        _selectedVariant = selected ? variant : null;
                      });
                    }
                  : null,
            );
          }).toList(),
        ),
        if (_selectedVariant != null) ...[
          const SizedBox(height: 16),
          Text(
            'Giá: ${_selectedVariant!.price} ₫',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              'Số lượng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _quantity > 1
                  ? () {
                      setState(() {
                        _quantity--;
                      });
                    }
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Text('$_quantity', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              onPressed: () {
                setState(() {
                  _quantity++;
                });
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(
            onPressed: _isTogglingFavorite ? null : _toggleFavorite,
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? AppColors.primary : null,
            ),
          ),
        ],
      ),
      body: FutureBuilder<_ProductDetailData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            // Show initial product if available while waiting
            if (widget.initialProduct != null) {
              return _buildProductContent(
                widget.initialProduct!,
                [],
                isWaiting: true,
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && !snapshot.hasData) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.message
                : 'Không thể tải chi tiết sản phẩm';

            return _ProductDetailStateMessage(
              icon: Icons.wifi_off_outlined,
              title: 'Có lỗi xảy ra',
              message: message,
              actionText: 'Thử lại',
              onActionPressed: _reloadProduct,
            );
          }

          final data = snapshot.data;

          if (data == null) {
            return _ProductDetailStateMessage(
              icon: Icons.inventory_2_outlined,
              title: 'Không có dữ liệu',
              message: 'Sản phẩm này chưa có thông tin để hiển thị.',
              actionText: 'Tải lại',
              onActionPressed: _reloadProduct,
            );
          }

          return _buildProductContent(
            data.product,
            data.variants,
            isWaiting: false,
          );
        },
      ),
    );
  }

  Widget _buildProductContent(
    Product product,
    List<ProductVariant> variants, {
    bool isWaiting = false,
  }) {
    return RefreshIndicator(
      onRefresh: () async => _reloadProduct(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProductImage(imageUrl: product.imageUrl),
          const SizedBox(height: 20),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.category_outlined,
                label: product.category.name,
              ),
              if (product.brand != null)
                _InfoChip(
                  icon: Icons.verified_outlined,
                  label: product.brand!.name,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Mô tả',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description?.isNotEmpty == true
                ? product.description!
                : 'Sản phẩm chưa có mô tả chi tiết.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary, height: 1.45),
          ),
          if (isWaiting) const SizedBox(height: 24),
          if (isWaiting) const Center(child: CircularProgressIndicator()),
          if (!isWaiting) ...[
            _buildVariantsSection(variants),
            _buildQuantitySection(),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isAddingToCart ? null : _addToCart,
              icon: _isAddingToCart
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.shopping_cart_outlined),
              label: const Text('Thêm vào giỏ hàng'),
            ),
            const SizedBox(height: 48),
            ReviewsSection(targetType: 'PRODUCT', targetId: widget.productId),
          ],
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Container(
          color: AppColors.primary.withValues(alpha: 0.08),
          child: url == null || url.isEmpty
              ? const Icon(
                  Icons.shopping_bag_outlined,
                  size: 54,
                  color: AppColors.primary,
                )
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image_outlined,
                      size: 54,
                      color: AppColors.primary,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailStateMessage extends StatelessWidget {
  const _ProductDetailStateMessage({
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
