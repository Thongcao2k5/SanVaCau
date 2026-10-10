import 'package:flutter/material.dart';

import '../data/cart_updates.dart';

class CartBadge extends StatelessWidget {
  const CartBadge({super.key, this.color, this.size = 25});
  final Color? color;
  final double size;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: CartUpdates.quantity,
    builder: (_, count, _) => Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: Icon(Icons.shopping_cart_outlined, color: color, size: size),
    ),
  );
}
