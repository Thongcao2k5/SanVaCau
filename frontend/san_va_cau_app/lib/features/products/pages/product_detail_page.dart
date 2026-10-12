import '../../cart/widgets/cart_badge.dart';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../cart/data/cart_api.dart';
import '../../cart/models/cart.dart';
import '../../favorites/data/favorite_api.dart';
import '../../orders/pages/checkout_page.dart';
import '../../reviews/widgets/reviews_section.dart';
import '../data/product_api.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../../cart/pages/cart_page.dart';
import '../../../core/widgets/app_image.dart';

class _ProductDetailData {
  _ProductDetailData(this.product, this.variants);
  final Product product;
  final List<ProductVariant> variants;
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    required this.productId,
    this.initialProduct,
    this.productApi,
    this.favoriteApi,
    this.cartApi,
    this.onCartPressed,
    super.key,
  });

  final String productId;
  final Product? initialProduct;
  final ProductApi? productApi;
  final FavoriteApi? favoriteApi;
  final CartApi? cartApi;
  final VoidCallback? onCartPressed;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductApi _productApi;
  late final FavoriteApi _favoriteApi;
  late final CartApi _cartApi;
  late Future<_ProductDetailData> _dataFuture;
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _isBuyingNow = false;
  bool _isFavorited = false;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _productApi = widget.productApi ?? ProductApi();
    _favoriteApi = widget.favoriteApi ?? FavoriteApi();
    _cartApi = widget.cartApi ?? CartApi();
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
    if (_selectedVariant == null) {
      final choices = [
        ...variants.where((variant) => variant.option1Value != null),
        ...variants.where((variant) => variant.option1Value == null),
      ];
      for (final variant in choices) {
        if (variant.isActive && variant.stockQuantity > 0) {
          _selectedVariant = variant;
          break;
        }
      }
    }
    return _ProductDetailData(product, variants);
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

    return '${buffer.toString()} đ';
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
      await _cartApi.addItem(
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

  Future<void> _buyNow(Product product) async {
    final variant = _selectedVariant;
    if (variant == null || variant.stockQuantity <= 0 || _isBuyingNow) return;

    setState(() => _isBuyingNow = true);
    try {
      final unitPrice = double.tryParse(variant.price) ?? 0;
      final cart = Cart(
        id: 'buy-now',
        customerId: '',
        totalAmount: unitPrice * _quantity,
        items: [
          CartItem(
            id: 'buy-now-item',
            productVariantId: variant.id,
            quantity: _quantity,
            unitPrice: unitPrice,
            lineTotal: unitPrice * _quantity,
            variant: CartVariant(
              id: variant.id,
              sku: variant.sku,
              variantName: variant.variantName,
              price: unitPrice,
              imageUrl: variant.imageUrl,
              product: CartProduct(
                id: product.id,
                name: product.name,
                imageUrl: product.imageUrl,
              ),
            ),
          ),
        ],
      );

      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CheckoutPage(
            cart: cart,
            buyNowProductVariantId: variant.id,
            buyNowQuantity: _quantity,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBuyingNow = false);
    }
  }

  Widget _optionImage(String? url) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: url == null || url.isEmpty
        ? const Icon(Icons.image_outlined)
        : AppImage(
            source: url,
            fit: BoxFit.contain,
            fallback: const Icon(Icons.image_outlined),
          ),
  );

  Widget _buildVariantsSection(List<ProductVariant> variants) {
    if (variants.isEmpty) return const SizedBox.shrink();

    final hasOptions = variants.any(
      (variant) => variant.option1Name != null && variant.option1Value != null,
    );
    final selected = _selectedVariant;
    String? option1Name;
    String? option2Name;
    for (final variant in variants) {
      option1Name ??= variant.option1Name;
      option2Name ??= variant.option2Name;
    }
    final option1Values = variants
        .map((variant) => variant.option1Value)
        .whereType<String>()
        .toSet()
        .toList();
    final option2Values = variants
        .where(
          (variant) =>
              selected?.option1Value == null ||
              variant.option1Value == selected?.option1Value,
        )
        .map((variant) => variant.option2Value)
        .whereType<String>()
        .toSet()
        .toList();

    Widget optionGroup(
      String label,
      List<String> values,
      String? selectedValue,
      bool firstOption,
    ) {
      final displayLabel = label
          .replaceAll(RegExp(r'^Chọn\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'[\[\]]'), '')
          .trim();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayLabel.isEmpty ? 'Biến thể' : displayLabel,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              final candidates = variants.where((variant) {
                if (firstOption) return variant.option1Value == value;
                return variant.option1Value == selected?.option1Value &&
                    variant.option2Value == value;
              }).toList();
              final available = candidates.any(
                (variant) => variant.isActive && variant.stockQuantity > 0,
              );
              return ChoiceChip(
                label: Text(value),
                selected: selectedValue == value,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
                onSelected: !available || selectedValue == value
                    ? null
                    : (_) {
                        ProductVariant? next;
                        for (final variant in candidates) {
                          final keepsSecondOption =
                              !firstOption ||
                              variant.option2Value == selected?.option2Value;
                          if (keepsSecondOption &&
                              variant.isActive &&
                              variant.stockQuantity > 0) {
                            next = variant;
                            break;
                          }
                        }
                        if (next == null) {
                          for (final variant in candidates) {
                            if (variant.isActive && variant.stockQuantity > 0) {
                              next = variant;
                              break;
                            }
                          }
                        }
                        if (next != null) {
                          setState(() {
                            _selectedVariant = next;
                            _quantity = 1;
                          });
                        }
                      },
                selectedColor: AppColors.primary,
                side: BorderSide(
                  color: selectedValue == value
                      ? AppColors.primary
                      : AppColors.border,
                ),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selectedValue == value
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: selectedValue == value
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasOptions) ...[
          Text(
            'Phân loại',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (hasOptions) ...[
          if (option1Name != null)
            optionGroup(
              option1Name,
              option1Values,
              selected?.option1Value,
              true,
            ),
          if (option2Name != null && option2Values.isNotEmpty) ...[
            const SizedBox(height: 14),
            optionGroup(
              option2Name,
              option2Values,
              selected?.option2Value,
              false,
            ),
          ],
        ] else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: variants.map((variant) {
              final isSelected = _selectedVariant?.id == variant.id;
              final isAvailable = variant.isActive && variant.stockQuantity > 0;
              final borderRadius = BorderRadius.circular(8);
              return Semantics(
                button: true,
                selected: isSelected,
                enabled: isAvailable,
                label: variant.variantName,
                child: Material(
                  color: isSelected
                      ? AppColors.primary
                      : (isAvailable
                            ? AppColors.surface
                            : AppColors.background),
                  shape: RoundedRectangleBorder(
                    borderRadius: borderRadius,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: borderRadius,
                    onTap: !isAvailable || isSelected
                        ? null
                        : () {
                            setState(() {
                              _selectedVariant = variant;
                              _quantity = 1;
                            });
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            variant.variantName,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isAvailable
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        if (_selectedVariant != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _selectedVariant!.stockQuantity > 0
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 16,
                color: _selectedVariant!.stockQuantity > 0
                    ? AppColors.success
                    : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                _selectedVariant!.stockQuantity > 0
                    ? 'Còn ${_selectedVariant!.stockQuantity} sản phẩm'
                    : 'Hết hàng',
                style: TextStyle(
                  color: _selectedVariant!.stockQuantity > 0
                      ? AppColors.success
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Row(
      children: [
        Text(
          'Số lượng',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _quantity > 1
                    ? () {
                        setState(() {
                          _quantity--;
                        });
                      }
                    : null,
                icon: Icon(
                  Icons.remove,
                  color: _quantity > 1
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                tooltip: 'Giảm số lượng',
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(),
              ),
              Container(width: 1, height: 24, color: AppColors.border),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_quantity',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.border),
              IconButton(
                onPressed:
                    _selectedVariant != null &&
                        _quantity < _selectedVariant!.stockQuantity
                    ? () {
                        setState(() {
                          _quantity++;
                        });
                      }
                    : null,
                icon: Icon(
                  Icons.add,
                  color:
                      (_selectedVariant != null &&
                          _quantity < _selectedVariant!.stockQuantity)
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                ),
                tooltip: 'Tăng số lượng',
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
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
            tooltip: 'Giỏ hàng',
            icon: const CartBadge(),
            onPressed:
                widget.onCartPressed ??
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CartPage(cartApi: _cartApi),
                  ),
                ),
          ),
          IconButton(
            onPressed: _isTogglingFavorite ? null : _toggleFavorite,
            tooltip: _isFavorited ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
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
    final selectedVariant = _selectedVariant;
    final canPurchase =
        !isWaiting &&
        selectedVariant != null &&
        selectedVariant.stockQuantity > 0;
    final total =
        (double.tryParse(selectedVariant?.price ?? '') ?? 0) * _quantity;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _reloadProduct(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                _ProductImage(
                  imageUrl: selectedVariant?.imageUrl ?? product.imageUrl,
                ),
                if ({product.imageUrl, ...variants.map((v) => v.imageUrl)}
                        .whereType<String>()
                        .where((url) => url.isNotEmpty)
                        .length >
                    1)
                  SizedBox(
                    height: 70,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children:
                          {product.imageUrl, ...variants.map((v) => v.imageUrl)}
                              .whereType<String>()
                              .where((url) => url.isNotEmpty)
                              .map(
                                (url) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SizedBox(
                                    width: 70,
                                    child: _optionImage(url),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  _formatMoney(
                    selectedVariant?.price ?? product.minPrice ?? '0',
                  ),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Mã: ${selectedVariant?.sku ?? product.id}'),
                const SizedBox(height: 6),
                Text('Thương hiệu: ${product.brand?.name ?? 'Đang cập nhật'}'),
                const SizedBox(height: 6),
                Text(
                  'Tình trạng: ${canPurchase
                      ? 'Còn hàng'
                      : isWaiting
                      ? 'Đang tải'
                      : 'Hết hàng'}',
                  style: TextStyle(
                    color: canPurchase
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 24),

                if (isWaiting) const Center(child: CircularProgressIndicator()),
                if (!isWaiting) ...[
                  _buildVariantsSection(variants),
                  const SizedBox(height: 24),
                  _buildQuantitySection(),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.border),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 24),
                  ReviewsSection(
                    targetType: 'PRODUCT',
                    targetId: widget.productId,
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
        if (!isWaiting)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: OutlinedButton.icon(
                        onPressed: !canPurchase || _isAddingToCart
                            ? null
                            : _addToCart,
                        icon: _isAddingToCart
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_shopping_cart),
                        label: const Text('Thêm vào giỏ'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 64,
                      child: FilledButton(
                        onPressed: !canPurchase || _isBuyingNow
                            ? null
                            : () => _buyNow(product),
                        child: _isBuyingNow
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Mua ngay'),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _formatMoney(total.toString()),
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
        aspectRatio: 1.5,
        child: Container(
          color: AppColors.borderMuted,
          child: url == null || url.isEmpty
              ? const Icon(
                  Icons.shopping_bag_outlined,
                  size: 54,
                  color: AppColors.textSecondary,
                )
              : AppImage(
                  source: url,
                  fit: BoxFit.contain,
                  fallback: const Icon(
                    Icons.broken_image_outlined,
                    size: 54,
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
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
