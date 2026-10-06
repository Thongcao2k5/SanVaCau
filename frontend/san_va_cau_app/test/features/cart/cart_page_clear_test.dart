import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/cart/data/cart_api.dart';
import 'package:san_va_cau_app/features/cart/models/cart.dart';
import 'package:san_va_cau_app/features/cart/pages/cart_page.dart';

class _FakeCartApi extends CartApi {
  _FakeCartApi({required this.initialCart, this.clearError});

  final Cart initialCart;
  final Object? clearError;
  int clearCallCount = 0;

  @override
  Future<Cart> getCart() async => initialCart;

  @override
  Future<Cart> clearCart() async {
    clearCallCount += 1;
    if (clearError case final error?) throw error;
    return _emptyCart;
  }
}

const _emptyCart = Cart(id: '1', customerId: '7', items: [], totalAmount: 0);

const _cartWithItem = Cart(
  id: '1',
  customerId: '7',
  items: [
    CartItem(
      id: '11',
      productVariantId: '21',
      quantity: 1,
      unitPrice: 120000,
      lineTotal: 120000,
      variant: CartVariant(
        id: '21',
        sku: 'VOT-01',
        variantName: '4U',
        price: 120000,
        product: CartProduct(id: '31', name: 'Vợt cầu lông'),
      ),
    ),
  ],
  totalAmount: 120000,
);

void main() {
  testWidgets('only shows clear action when the cart has items', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CartPage(cartApi: _FakeCartApi(initialCart: _emptyCart)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Xóa toàn bộ giỏ hàng'), findsNothing);
    expect(find.text('Giỏ hàng trống'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation does not clear the cart', (
    tester,
  ) async {
    final api = _FakeCartApi(initialCart: _cartWithItem);
    await tester.pumpWidget(MaterialApp(home: CartPage(cartApi: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xóa toàn bộ giỏ hàng'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa toàn bộ giỏ hàng?'), findsOneWidget);

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(api.clearCallCount, 0);
    expect(find.text('Vợt cầu lông'), findsOneWidget);
  });

  testWidgets('confirming clears the cart and shows the empty state', (
    tester,
  ) async {
    final api = _FakeCartApi(initialCart: _cartWithItem);
    await tester.pumpWidget(MaterialApp(home: CartPage(cartApi: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xóa toàn bộ giỏ hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa tất cả'));
    await tester.pumpAndSettle();

    expect(api.clearCallCount, 1);
    expect(find.text('Giỏ hàng trống'), findsOneWidget);
    expect(find.text('Đã xóa toàn bộ giỏ hàng'), findsOneWidget);
    expect(find.byTooltip('Xóa toàn bộ giỏ hàng'), findsNothing);
  });

  testWidgets('keeps cart items and reports an API error', (tester) async {
    final api = _FakeCartApi(
      initialCart: _cartWithItem,
      clearError: const ApiException(
        statusCode: 500,
        message: 'Không thể xóa giỏ hàng lúc này',
      ),
    );
    await tester.pumpWidget(MaterialApp(home: CartPage(cartApi: api)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xóa toàn bộ giỏ hàng'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa tất cả'));
    await tester.pumpAndSettle();

    expect(api.clearCallCount, 1);
    expect(find.text('Vợt cầu lông'), findsOneWidget);
    expect(find.text('Không thể xóa giỏ hàng lúc này'), findsOneWidget);
    expect(find.byTooltip('Xóa toàn bộ giỏ hàng'), findsOneWidget);
  });
}
