import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/cart/data/cart_api.dart';
import 'package:san_va_cau_app/features/cart/models/cart.dart';
import 'package:san_va_cau_app/features/products/data/product_api.dart';
import 'package:san_va_cau_app/features/products/models/product.dart';
import 'package:san_va_cau_app/features/products/models/product_variant.dart';
import 'package:san_va_cau_app/features/products/widgets/product_card.dart';

class _FakeProductApi extends ProductApi {
  _FakeProductApi(this.variants);

  final List<ProductVariant> variants;
  int variantRequests = 0;

  @override
  Future<List<ProductVariant>> getProductVariants(String productId) async {
    variantRequests++;
    return variants;
  }
}

class _PendingProductApi extends ProductApi {
  final completer = Completer<List<ProductVariant>>();
  int variantRequests = 0;

  @override
  Future<List<ProductVariant>> getProductVariants(String productId) {
    variantRequests++;
    return completer.future;
  }
}

class _FakeCartApi extends CartApi {
  _FakeCartApi({this.error});

  final Object? error;
  final addedVariantIds = <String>[];

  @override
  Future<Cart> addItem({
    required String productVariantId,
    required int quantity,
  }) async {
    if (error != null) throw error!;
    addedVariantIds.add(productVariantId);
    return const Cart(id: '1', customerId: '1', items: [], totalAmount: 0);
  }
}

Product _product({String? minPrice = '2900000'}) => Product(
  id: '9',
  categoryId: '2',
  brandId: '4',
  name: 'Yonex Astrox 99 Pro',
  isActive: true,
  isFeatured: true,
  createdAt: DateTime.utc(2026, 10, 1),
  updatedAt: DateTime.utc(2026, 10, 1),
  category: const ProductCategory(id: '2', name: 'Vợt cầu lông'),
  brand: const ProductBrand(id: '4', name: 'Yonex'),
  minPrice: minPrice,
);

ProductVariant _variant(String id, String name) => ProductVariant(
  id: id,
  productId: '9',
  sku: 'SKU-$id',
  variantName: name,
  price: '2900000',
  isActive: true,
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required ProductApi productApi,
  required CartApi cartApi,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 220,
          height: 380,
          child: ProductCard(
            product: _product(),
            productApi: productApi,
            cartApi: cartApi,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows minimum price and opens product when card is tapped', (
    tester,
  ) async {
    var taps = 0;
    await _pumpCard(
      tester,
      productApi: _FakeProductApi(const []),
      cartApi: _FakeCartApi(),
      onTap: () => taps++,
    );

    expect(find.text('2.900.000đ'), findsOneWidget);
    await tester.tap(find.text('Yonex Astrox 99 Pro'));
    expect(taps, 1);
  });

  testWidgets('adds the only active variant without opening product', (
    tester,
  ) async {
    var cardTaps = 0;
    final productApi = _FakeProductApi([_variant('11', '4U G5')]);
    final cartApi = _FakeCartApi();
    await _pumpCard(
      tester,
      productApi: productApi,
      cartApi: cartApi,
      onTap: () => cardTaps++,
    );

    await tester.tap(find.byTooltip('Thêm vào giỏ hàng'));
    await tester.pumpAndSettle();

    expect(cartApi.addedVariantIds, ['11']);
    expect(cardTaps, 0);
    expect(find.text('Đã thêm sản phẩm vào giỏ hàng'), findsOneWidget);
  });

  testWidgets('asks the user to choose when multiple variants are active', (
    tester,
  ) async {
    final productApi = _FakeProductApi([
      _variant('11', '4U G5'),
      _variant('12', '3U G5'),
    ]);
    final cartApi = _FakeCartApi();
    await _pumpCard(tester, productApi: productApi, cartApi: cartApi);

    await tester.tap(find.byTooltip('Thêm vào giỏ hàng'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Chọn phân loại'), findsOneWidget);

    await tester.tap(find.text('3U G5'));
    await tester.pumpAndSettle();
    expect(cartApi.addedVariantIds, ['12']);
  });

  testWidgets('shows a login message when adding to cart returns 401', (
    tester,
  ) async {
    final productApi = _FakeProductApi([_variant('11', '4U G5')]);
    final cartApi = _FakeCartApi(
      error: const ApiException(statusCode: 401, message: 'Unauthorized'),
    );
    await _pumpCard(tester, productApi: productApi, cartApi: cartApi);

    await tester.tap(find.byTooltip('Thêm vào giỏ hàng'));
    await tester.pumpAndSettle();

    expect(
      find.text('Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng'),
      findsOneWidget,
    );
  });

  testWidgets(
    'ignores a repeated cart tap while the first request is running',
    (tester) async {
      final productApi = _PendingProductApi();
      final cartApi = _FakeCartApi();
      await _pumpCard(tester, productApi: productApi, cartApi: cartApi);

      final cartButton = find.byTooltip('Thêm vào giỏ hàng');
      await tester.tap(cartButton);
      await tester.pump();
      await tester.tap(cartButton);
      productApi.completer.complete([_variant('11', '4U G5')]);
      await tester.pumpAndSettle();

      expect(productApi.variantRequests, 1);
      expect(cartApi.addedVariantIds, ['11']);
    },
  );
}
