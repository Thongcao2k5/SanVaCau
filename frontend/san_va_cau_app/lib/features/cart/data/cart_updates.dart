import 'package:flutter/foundation.dart';

import '../models/cart.dart';

class CartUpdates {
  static Cart? latest;
  static final quantity = ValueNotifier<int>(0);
  static final revision = ValueNotifier<int>(0);
  static Cart publish(Cart cart, {bool changed = false}) {
    latest = cart;
    quantity.value = cart.items.fold(0, (sum, item) => sum + item.quantity);
    if (changed) revision.value++;
    return cart;
  }

  static void reset() {
    latest = null;
    quantity.value = 0;
    revision.value++;
  }
}
