import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/theme/app_colors.dart';
import 'package:san_va_cau_app/features/cart/data/cart_api.dart';
import 'package:san_va_cau_app/features/cart/models/cart.dart';
import 'package:san_va_cau_app/features/cart/pages/cart_page.dart';

class _FakeCartApi extends CartApi {
  _FakeCartApi({
    required this.initialCart,
    this.clearError,
    this.removeError,
    this.addError,
  });

  final Cart initialCart;
  final Object? clearError;
  final Object? removeError;
  final Object? addError;
  int clearCallCount = 0;
  int removeCallCount = 0;
  int addCallCount = 0;

  @override
  Future<Cart> getCart() async => initialCart;

  @override
  Future<Cart> clearCart() async {
    clearCallCount += 1;
    if (clearError case final error?) throw error;
    return _emptyCart;
  }

  @override
  Future<Cart> removeItem(String itemId) async {
    removeCallCount += 1;
    if (removeError case final error?) throw error;
    return _emptyCart;
  }

  @override
  Future<Cart> addItem({
    required String productVariantId,
    required int quantity,
  }) async {
    addCallCount += 1;
    if (addError case final error?) throw error;
    return initialCart;
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
  testWidgets('quantity changes use API result without reloading the list', (
    tester,
  ) async {
    final api = _UpdatingCartApi();
    await tester.pumpWidget(MaterialApp(home: CartPage(cartApi: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tăng số lượng'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Giỏ hàng (2)'), findsOneWidget);
    expect(find.text('240.000 đ'), findsOneWidget);
    expect(api.loads, 1);
  });
  testWidgets('cart selection and prices fit on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: CartPage(cartApi: _FakeCartApi(initialCart: _cartWithItem)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Giỏ hàng (1)'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Thanh toán'), findsNothing);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Thanh toán'))
          .onPressed,
      isNotNull,
    );
    expect(find.text('120.000 đ'), findsNWidgets(2));
  });

  testWidgets('swipe delete removes the item without a framework error', (
    tester,
  ) async {
    final api = _FakeCartApi(initialCart: _cartWithItem);
    await tester.pumpWidget(MaterialApp(home: CartPage(cartApi: api)));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(Dismissible), const Offset(-600, 0), 2000);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.removeCallCount, 1);
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
    expect(find.text('Đã xóa sản phẩm'), findsOneWidget);
    final noticeMaterial = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('Đã xóa sản phẩm'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(noticeMaterial.color, AppColors.primarySoft);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Đã xóa sản phẩm'), findsNothing);
  });

  testWidgets('restores the item when swipe delete fails', (tester) async {
    final api = _FakeCartApi(
      initialCart: _cartWithItem,
      removeError: const ApiException(
        statusCode: 500,
        message: 'Không thể xóa sản phẩm lúc này',
      ),
    );
    await tester.pumpWidget(MaterialApp(home: CartPage(cartApi: api)));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(Dismissible), const Offset(-600, 0), 2000);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.removeCallCount, 1);
    expect(find.text('Vợt cầu lông'), findsOneWidget);
    expect(find.text('Không thể xóa sản phẩm lúc này'), findsOneWidget);
  });

  testWidgets('keeps the item deleted when undo fails', (tester) async {
    final api = _FakeCartApi(
      initialCart: _cartWithItem,
      addError: const ApiException(
        statusCode: 500,
        message: 'Không thể hoàn tác lúc này',
      ),
    );
    await tester.pumpWidget(MaterialApp(home: CartPage(cartApi: api)));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(Dismissible), const Offset(-600, 0), 2000);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.addCallCount, 1);
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
    expect(find.text('Vợt cầu lông'), findsNothing);
    expect(find.text('Không thể hoàn tác lúc này'), findsOneWidget);
  });

  testWidgets('restores the item when undo succeeds', (tester) async {
    final api = _FakeCartApi(initialCart: _cartWithItem);
    await tester.pumpWidget(MaterialApp(home: CartPage(cartApi: api)));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(Dismissible), const Offset(-600, 0), 2000);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.addCallCount, 1);
    expect(find.text('Vợt cầu lông'), findsOneWidget);
    expect(find.text('Giỏ hàng (1)'), findsOneWidget);
  });
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
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
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
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
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

class _UpdatingCartApi extends _FakeCartApi {
  _UpdatingCartApi() : super(initialCart: _cartWithItem);
  int loads = 0;
  @override
  Future<Cart> getCart() async {
    loads++;
    return initialCart;
  }

  @override
  Future<Cart> updateQuantity({
    required String itemId,
    required int quantity,
  }) async {
    final item = initialCart.items.first;
    return Cart(
      id: initialCart.id,
      customerId: initialCart.customerId,
      totalAmount: item.unitPrice * quantity,
      items: [
        CartItem(
          id: item.id,
          productVariantId: item.productVariantId,
          quantity: quantity,
          unitPrice: item.unitPrice,
          lineTotal: item.unitPrice * quantity,
          variant: item.variant,
        ),
      ],
    );
  }
}
