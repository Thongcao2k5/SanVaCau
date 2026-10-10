import '../data/cart_updates.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/constants/api_config.dart';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/cart_api.dart';
import '../models/cart.dart';
import '../../orders/pages/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, this.cartApi});

  final CartApi? cartApi;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final CartApi _cartApi;
  late Future<Cart> _cartFuture;
  bool _isClearingCart = false;
  bool _isUpdating = false;
  final _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _cartApi = widget.cartApi ?? CartApi();
    _cartFuture = _cartApi.getCart();
    CartUpdates.revision.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    CartUpdates.revision.removeListener(_onCartChanged);
    super.dispose();
  }

  void _reloadCart() {
    setState(() {
      _cartFuture = _cartApi.getCart();
    });
  }

  void _onCartChanged() {
    final cart = CartUpdates.latest;
    if (cart == null) {
      _reloadCart();
    } else if (mounted) {
      setState(() => _cartFuture = Future.value(cart));
    }
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    if (_isUpdating || _isClearingCart) return;
    setState(() => _isUpdating = true);
    try {
      final cart = quantity <= 0
          ? await _cartApi.removeItem(item.id)
          : await _cartApi.updateQuantity(itemId: item.id, quantity: quantity);
      if (mounted) setState(() => _cartFuture = Future.value(cart));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Không thể cập nhật số lượng. Vui lòng thử lại.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _confirmClearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa toàn bộ giỏ hàng?'),
        content: const Text(
          'Tất cả sản phẩm trong giỏ hàng sẽ bị xóa. Bạn không thể hoàn tác thao tác này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isClearingCart = true;
    });

    try {
      final emptyCart = await _cartApi.clearCart();
      if (!mounted) return;

      setState(() {
        _cartFuture = Future.value(emptyCart);
        _isClearingCart = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa toàn bộ giỏ hàng')));
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isClearingCart = false;
      });
      final message = error is ApiException
          ? error.message
          : 'Không thể xóa giỏ hàng';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Cart>(
          future: _cartFuture,
          builder: (_, snapshot) => Text(
            'Giỏ hàng (${snapshot.data?.items.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0})',
          ),
        ),
        actions: [
          FutureBuilder<Cart>(
            future: _cartFuture,
            builder: (context, snapshot) {
              if (snapshot.data?.items.isNotEmpty != true) {
                return const SizedBox.shrink();
              }

              if (_isClearingCart) {
                return const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              return IconButton(
                tooltip: 'Xóa toàn bộ giỏ hàng',
                onPressed: _confirmClearCart,
                icon: const Icon(Icons.delete_sweep_outlined),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Cart>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.message
                : 'Không thể tải giỏ hàng';

            return _CartStateMessage(
              icon: Icons.shopping_cart_outlined,
              title: 'Chưa thể mở giỏ hàng',
              message: message,
              actionText: 'Thử lại',
              onActionPressed: _reloadCart,
            );
          }

          final cart = snapshot.data;

          if (cart == null || cart.items.isEmpty) {
            return _CartStateMessage(
              icon: Icons.shopping_cart_outlined,
              title: 'Giỏ hàng trống',
              message: 'Sản phẩm bạn thêm vào giỏ sẽ hiển thị ở đây.',
              actionText: 'Tải lại',
              onActionPressed: _reloadCart,
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _reloadCart(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];

                      return _CartItemCard(
                        key: ValueKey(item.id),
                        busy: _isUpdating || _isClearingCart,
                        item: item,
                        selected: _selected.contains(item.id),
                        onSelected: (value) => setState(() {
                          if (value) {
                            _selected.add(item.id);
                          } else {
                            _selected.remove(item.id);
                          }
                        }),
                        onDecrease: () =>
                            _updateQuantity(item, item.quantity - 1),
                        onIncrease: () =>
                            _updateQuantity(item, item.quantity + 1),
                        onRemove: () => _updateQuantity(item, 0),
                      );
                    },
                  ),
                ),
              ),
              _CartSummary(
                cart: Cart(
                  id: cart.id,
                  customerId: cart.customerId,
                  items: cart.items
                      .where((item) => _selected.contains(item.id))
                      .toList(),
                  totalAmount: cart.items
                      .where((item) => _selected.contains(item.id))
                      .fold<double>(0, (sum, item) => sum + item.lineTotal),
                ),
                allSelected: cart.items.every(
                  (item) => _selected.contains(item.id),
                ),
                onSelectAll: (value) => setState(() {
                  _selected.clear();
                  if (value) {
                    _selected.addAll(cart.items.map((item) => item.id));
                  }
                }),
                onCheckoutSuccess: _reloadCart,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    super.key,
    required this.busy,
    required this.item,
    required this.selected,
    required this.onSelected,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CartItem item;
  final bool busy;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.variant.imageUrl ?? item.variant.product.imageUrl;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              onChanged: (value) => onSelected(value ?? false),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 88,
                height: 104,
                color: AppColors.primary.withValues(alpha: 0.08),
                child: imageUrl == null || imageUrl.isEmpty
                    ? const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.primary,
                      )
                    : AppImage(
                        source: imageUrl.startsWith('assets/')
                            ? imageUrl
                            : ApiConfig.resolveMediaUrl(imageUrl),
                        fit: BoxFit.contain,
                        fallback: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.variant.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.variant.variantName,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatMoney(item.lineTotal),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          maximumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: busy ? null : onDecrease,
                        icon: const Icon(Icons.remove, size: 16),
                        tooltip: 'Giảm số lượng',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          item.quantity.toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          maximumSize: const Size(32, 32),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: busy ? null : onIncrease,
                        icon: const Icon(Icons.add, size: 16),
                        tooltip: 'Tăng số lượng',
                      ),

                      IconButton(
                        onPressed: busy ? null : onRemove,
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Xóa sản phẩm',
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

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.cart,
    required this.onCheckoutSuccess,
    required this.allSelected,
    required this.onSelectAll,
  });

  final Cart cart;
  final bool allSelected;
  final ValueChanged<bool> onSelectAll;
  final VoidCallback onCheckoutSuccess;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Checkbox(
              value: allSelected,
              onChanged: (value) => onSelectAll(value ?? false),
            ),
            const Text('Tất cả', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tạm tính',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatMoney(cart.totalAmount),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: FilledButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CheckoutPage(cart: cart),
                          ),
                        );

                        if (result == true) {
                          onCheckoutSuccess();
                        }
                      },
                child: const FittedBox(child: Text('Thanh toán', maxLines: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartStateMessage extends StatelessWidget {
  const _CartStateMessage({
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

String _formatMoney(double value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < rounded.length; i++) {
    final reverseIndex = rounded.length - i;
    buffer.write(rounded[i]);

    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return '${buffer.toString()} đ';
}
