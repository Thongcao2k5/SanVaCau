import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../cart/data/cart_api.dart';
import '../data/product_api.dart';
import '../models/product.dart';
import '../models/product_variant.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    required this.product,
    required this.onTap,
    this.productApi,
    this.cartApi,
    super.key,
  });

  final Product product;
  final VoidCallback onTap;
  final ProductApi? productApi;
  final CartApi? cartApi;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late final ProductApi _productApi;
  late final CartApi _cartApi;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _productApi = widget.productApi ?? ProductApi();
    _cartApi = widget.cartApi ?? CartApi();
  }

  String _formatMoney(String value) {
    final digits = (double.tryParse(value) ?? 0).round().toString();
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()}đ';
  }

  Future<void> _handleAddToCart() async {
    if (_isAddingToCart) return;

    setState(() {
      _isAddingToCart = true;
    });

    try {
      final variants = await _productApi.getProductVariants(widget.product.id);
      final activeVariants = variants.where((v) => v.isActive).toList();

      if (!mounted) return;

      if (activeVariants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sản phẩm hiện đang tạm hết hàng')),
        );
        return;
      }

      if (activeVariants.length == 1) {
        await _addToCartVariant(activeVariants.first.id);
      } else {
        final selectedVariantId = await showModalBottomSheet<String>(
          context: context,
          builder: (_) => _VariantSelectionSheet(variants: activeVariants),
        );
        if (selectedVariantId != null && mounted) {
          await _addToCartVariant(selectedVariantId);
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  Future<void> _addToCartVariant(String variantId) async {
    await _cartApi.addItem(productVariantId: variantId, quantity: 1);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm sản phẩm vào giỏ hàng')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPrice = widget.product.minPrice != null;
    final priceText = hasPrice
        ? _formatMoney(widget.product.minPrice!)
        : 'Liên hệ';

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderMuted, width: 1),
      ),
      elevation: 0,
      color: AppColors.surface,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: _ProductImage(imageUrl: widget.product.imageUrl),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.brand != null) ...[
                      Text(
                        widget.product.brand!.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            priceText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: hasPrice
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            tooltip: 'Thêm vào giỏ hàng',
                            onPressed: hasPrice ? _handleAddToCart : null,
                            icon: _isAddingToCart
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.add_shopping_cart,
                                    color: hasPrice
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    size: 20,
                                  ),
                          ),
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
    );
  }
}

class _VariantSelectionSheet extends StatelessWidget {
  const _VariantSelectionSheet({required this.variants});

  final List<ProductVariant> variants;

  String _formatMoney(String value) {
    final digits = (double.tryParse(value) ?? 0).round().toString();
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()}đ';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Chọn phân loại',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: variants.length,
                itemBuilder: (context, index) {
                  final variant = variants[index];
                  return ListTile(
                    title: Text(
                      variant.variantName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _formatMoney(variant.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(variant.id),
                  );
                },
              ),
            ),
          ],
        ),
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

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: url == null || url.isEmpty
          ? const Icon(Icons.shopping_bag_outlined, color: AppColors.primary)
          : AppImage(
              source: url,
              fit: BoxFit.contain,
              fallback: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.primary,
              ),
            ),
    );
  }
}
