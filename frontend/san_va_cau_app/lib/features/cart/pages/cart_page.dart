import '../data/cart_updates.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/constants/api_config.dart';

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/cart_api.dart';
import '../models/cart.dart';
import '../../orders/pages/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, this.cartApi, this.onSelectionChanged});

  final CartApi? cartApi;
  final ValueChanged<bool>? onSelectionChanged;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final CartApi _cartApi;
  late Future<Cart> _cartFuture;
  bool _isClearingCart = false;
  bool _isUpdating = false;
  final _selected = <String>{};
  final _dismissedItemIds = <String>{};
  final _itemKeyVersions = <String, int>{};
  bool _lastReportedHasSelection = false;

  void _notifySelectionChanged() {
    final hasSelection = _selected.isNotEmpty;
    if (_lastReportedHasSelection == hasSelection) return;
    _lastReportedHasSelection = hasSelection;
    widget.onSelectionChanged?.call(hasSelection);
  }

  void _updateSelection(VoidCallback update) {
    setState(update);
    _notifySelectionChanged();
  }

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
      setState(() {
        _selected.retainAll(cart.items.map((item) => item.id));
        _cartFuture = Future.value(cart);
      });
      _notifySelectionChanged();
    }
  }

  Future<void> _updateQuantity(CartItem item, int quantity) async {
    if (_isUpdating || _isClearingCart) return;
    setState(() => _isUpdating = true);
    try {
      final cart = quantity <= 0
          ? await _cartApi.removeItem(item.id)
          : await _cartApi.updateQuantity(itemId: item.id, quantity: quantity);
      if (mounted) {
        setState(() {
          _selected.retainAll(cart.items.map((item) => item.id));
          _cartFuture = Future.value(cart);
        });
        _notifySelectionChanged();
      }
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

  Future<void> _removeWithUndo(
    CartItem item,
    Cart currentCart, {
    required bool wasSelected,
  }) async {
    if (_isUpdating || _isClearingCart) return;
    setState(() => _isUpdating = true);

    late final Cart deletedCart;
    try {
      deletedCart = await _cartApi.removeItem(item.id);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (wasSelected) _selected.add(item.id);
        _itemKeyVersions.update(
          item.id,
          (version) => version + 1,
          ifAbsent: () => 1,
        );
        _dismissedItemIds.remove(item.id);
        _cartFuture = Future.value(currentCart);
        _isUpdating = false;
      });
      _notifySelectionChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException ? error.message : 'Không thể xóa sản phẩm',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _cartFuture = Future.value(deletedCart);
      _isUpdating = false;
    });

    final shouldUndo = await _showUndoNotice();
    if (!shouldUndo || !mounted) return;

    setState(() => _isUpdating = true);
    try {
      final restored = await _cartApi.addItem(
        productVariantId: item.productVariantId,
        quantity: item.quantity,
      );
      if (!mounted) return;
      if (wasSelected) {
        final restoredItem = restored.items
            .where(
              (candidate) =>
                  candidate.productVariantId == item.productVariantId,
            )
            .firstOrNull;
        if (restoredItem != null) _selected.add(restoredItem.id);
      }
      setState(() {
        _itemKeyVersions.update(
          item.id,
          (version) => version + 1,
          ifAbsent: () => 1,
        );
        _dismissedItemIds.remove(item.id);
        _cartFuture = Future.value(restored);
      });
      _notifySelectionChanged();
    } catch (error) {
      if (mounted) {
        setState(() {
          _cartFuture = Future.value(deletedCart);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Không thể hoàn tác. Vui lòng thêm lại sản phẩm.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<bool> _showUndoNotice() {
    final completer = Completer<bool>();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    Timer? timer;
    var closed = false;

    void close(bool undo) {
      if (closed) return;
      closed = true;
      timer?.cancel();
      entry.remove();
      completer.complete(undo);
    }

    entry = OverlayEntry(
      builder: (overlayContext) {
        final topInset = MediaQuery.viewPaddingOf(overlayContext).top;
        final screenWidth = MediaQuery.sizeOf(overlayContext).width;
        return Positioned(
          top: topInset + 12,
          right: 12,
          width: screenWidth.clamp(0, 330).toDouble() - 24,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(24 * (1 - value), 0),
              child: Opacity(opacity: value, child: child),
            ),
            child: Material(
              color: AppColors.primarySoft,
              elevation: 8,
              shadowColor: AppColors.primary.withValues(alpha: 0.16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.primary,
                      size: 21,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Đã xóa sản phẩm',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                      ),
                      onPressed: () => close(true),
                      child: const Text('Hoàn tác'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    timer = Timer(const Duration(seconds: 2), () => close(false));
    return completer.future;
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
        _selected.clear();
        _cartFuture = Future.value(emptyCart);
        _isClearingCart = false;
      });
      _notifySelectionChanged();
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
          builder: (_, snapshot) {
            final quantity =
                snapshot.data?.items
                    .where((item) => !_dismissedItemIds.contains(item.id))
                    .fold<int>(0, (sum, item) => sum + item.quantity) ??
                0;
            return Text('Giỏ hàng ($quantity)');
          },
        ),
        actions: [
          FutureBuilder<Cart>(
            future: _cartFuture,
            builder: (context, snapshot) {
              final hasVisibleItems =
                  snapshot.data?.items.any(
                    (item) => !_dismissedItemIds.contains(item.id),
                  ) ??
                  false;
              if (!hasVisibleItems) {
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

          if (cart == null) {
            return const SizedBox.shrink();
          }

          final visibleItems = cart.items
              .where((item) => !_dismissedItemIds.contains(item.id))
              .toList();

          if (visibleItems.isEmpty) {
            return _CartStateMessage(
              icon: Icons.shopping_cart_outlined,
              title: 'Giỏ hàng đang trống',
              message: 'Sản phẩm bạn thêm vào giỏ sẽ xuất hiện tại đây.',
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
                    itemCount: visibleItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = visibleItems[index];

                      return Dismissible(
                        key: ValueKey(
                          '${item.id}:${_itemKeyVersions[item.id] ?? 0}',
                        ),
                        direction: _isUpdating || _isClearingCart
                            ? DismissDirection.none
                            : DismissDirection.endToStart,
                        dismissThresholds: const {
                          DismissDirection.endToStart: 0.35,
                        },
                        onDismissed: (_) {
                          final wasSelected = _selected.contains(item.id);
                          _updateSelection(() {
                            _selected.remove(item.id);
                            _dismissedItemIds.add(item.id);
                          });
                          unawaited(
                            _removeWithUndo(
                              item,
                              cart,
                              wasSelected: wasSelected,
                            ),
                          );
                        },
                        background: const _DeleteBackground(),
                        child: _CartItemCard(
                          busy: _isUpdating || _isClearingCart,
                          item: item,
                          selected: _selected.contains(item.id),
                          onSelected: (value) => _updateSelection(() {
                            if (value) {
                              _selected.add(item.id);
                            } else {
                              _selected.remove(item.id);
                            }
                          }),
                          onDecrease: item.quantity <= 1
                              ? null
                              : () => _updateQuantity(item, item.quantity - 1),
                          onIncrease: () =>
                              _updateQuantity(item, item.quantity + 1),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_selected.isNotEmpty)
                _CartSummary(
                  cart: Cart(
                    id: cart.id,
                    customerId: cart.customerId,
                    items: visibleItems
                        .where((item) => _selected.contains(item.id))
                        .toList(),
                    totalAmount: visibleItems
                        .where((item) => _selected.contains(item.id))
                        .fold<double>(0, (sum, item) => sum + item.lineTotal),
                  ),
                  allSelected: visibleItems.every(
                    (item) => _selected.contains(item.id),
                  ),
                  onSelectAll: (value) => _updateSelection(() {
                    _selected.clear();
                    if (value) {
                      _selected.addAll(visibleItems.map((item) => item.id));
                    }
                  }),
                  onCheckoutSuccess: () {
                    _updateSelection(_selected.clear);
                    _reloadCart();
                  },
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
    required this.busy,
    required this.item,
    required this.selected,
    required this.onSelected,
    required this.onDecrease,
    required this.onIncrease,
  });

  final CartItem item;
  final bool busy;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.variant.imageUrl ?? item.variant.product.imageUrl;

    return Card(
      elevation: 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: selected,
              shape: const CircleBorder(),
              onChanged: (value) => onSelected(value ?? false),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 88,
                height: 96,
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
            Container(
              width: 2,
              height: 72,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
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
                  const SizedBox(height: 6),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints.tightFor(
                                width: 44,
                                height: 44,
                              ),
                              onPressed: busy ? null : onDecrease,
                              icon: const Icon(Icons.remove, size: 18),
                              tooltip: 'Giảm số lượng',
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                item.quantity.toString(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints.tightFor(
                                width: 44,
                                height: 44,
                              ),
                              onPressed: busy ? null : onIncrease,
                              icon: const Icon(Icons.add, size: 18),
                              tooltip: 'Tăng số lượng',
                            ),
                          ],
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
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: Colors.white),
          SizedBox(height: 4),
          Text(
            'Xóa',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 18,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Checkbox(
                  value: allSelected,
                  shape: const CircleBorder(),
                  onChanged: (value) => onSelectAll(value ?? false),
                ),
                const Text(
                  'Tất cả',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã chọn ${cart.items.length} sản phẩm',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 132,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(shape: const StadiumBorder()),
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
                    child: const FittedBox(
                      child: Text('Thanh toán', maxLines: 1),
                    ),
                  ),
                ),
              ],
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
