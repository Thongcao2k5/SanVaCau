import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/cart/data/cart_api.dart';
import 'package:san_va_cau_app/features/cart/models/cart.dart';
import 'package:san_va_cau_app/features/favorites/data/favorite_api.dart';
import 'package:san_va_cau_app/features/products/data/product_api.dart';
import 'package:san_va_cau_app/features/products/models/product.dart';
import 'package:san_va_cau_app/features/products/models/product_variant.dart';
import 'package:san_va_cau_app/features/products/pages/product_detail_page.dart';

class _FakeProductApi extends ProductApi {
  _FakeProductApi(this.product, this.variants);

  final Product product;
  final List<ProductVariant> variants;

  @override
  Future<Product> getProductById(String id) async => product;

  @override
  Future<List<ProductVariant>> getProductVariants(String productId) async =>
      variants;
}

class _FakeCartApi extends CartApi {
  final addedVariantIds = <String>[];

  @override
  Future<Cart> addItem({
    required String productVariantId,
    required int quantity,
  }) async {
    addedVariantIds.add(productVariantId);
    return const Cart(id: '1', customerId: '1', items: [], totalAmount: 0);
  }
}

class _FakeFavoriteApi extends FavoriteApi {
  @override
  Future<bool> checkFavorite(String targetType, String targetId) async => false;
}

Product _product() => Product(
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
  description: 'Test description',
);

ProductVariant _variant(
  String id,
  String name, {
  int stock = 10,
  String price = '2900000',
}) => ProductVariant(
  id: id,
  productId: '9',
  sku: 'SKU-$id',
  variantName: name,
  price: price,
  isActive: true,
  stockQuantity: stock,
);

Future<void> _pumpPage(
  WidgetTester tester, {
  required ProductApi productApi,
  required CartApi cartApi,
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    MaterialApp(
      home: ProductDetailPage(
        productId: '9',
        productApi: productApi,
        favoriteApi: _FakeFavoriteApi(),
        cartApi: cartApi,
      ),
    ),
  );

  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('The first in-stock variant is selected by default', (
    tester,
  ) async {
    final variants = [
      _variant('1', 'Out of stock', stock: 0),
      _variant('2', 'In stock', stock: 5),
    ];
    await _pumpPage(
      tester,
      productApi: _FakeProductApi(_product(), variants),
      cartApi: _FakeCartApi(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Còn 5 sản phẩm'), findsOneWidget);
  });

  testWidgets('Unit price is visible near the product title', (tester) async {
    await _pumpPage(
      tester,
      productApi: _FakeProductApi(_product(), [_variant('1', 'Var 1')]),
      cartApi: _FakeCartApi(),
    );
    await tester.pumpAndSettle();

    // Text widget containing the format money near the title
    expect(find.text('2.900.000 đ'), findsWidgets);
  });

  testWidgets(
    'Total price updates when quantity changes and remains a single Text widget with maxLines: 1',
    (tester) async {
      await _pumpPage(
        tester,
        productApi: _FakeProductApi(_product(), [
          _variant('1', 'Var 1', price: '100000'),
        ]),
        cartApi: _FakeCartApi(),
      );
      await tester.pumpAndSettle();

      // Initial total
      expect(find.text('100.000 đ'), findsWidgets);

      // Increase quantity
      await tester.tap(find.byTooltip('Tăng số lượng'));
      await tester.pumpAndSettle();

      // Updated total (2 * 100000 = 200000)
      expect(find.text('200.000 đ'), findsWidgets);

      // Check maxLines: 1 on the total price Text widget
      // The total price text is a descendant of FittedBox.
      final totalTextFinder = find.descendant(
        of: find.byType(FittedBox),
        matching: find.text('200.000 đ'),
      );
      expect(totalTextFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(totalTextFinder);
      expect(textWidget.maxLines, 1);
    },
  );

  testWidgets('Out-of-stock variants cannot be selected', (tester) async {
    final variants = [
      _variant('1', 'In stock', stock: 5),
      _variant('2', 'Out of stock', stock: 0),
    ];
    await _pumpPage(
      tester,
      productApi: _FakeProductApi(_product(), variants),
      cartApi: _FakeCartApi(),
    );
    await tester.pumpAndSettle();

    // Tap on the out of stock variant
    await tester.tap(find.text('Out of stock'));
    await tester.pumpAndSettle();

    // The selected variant should remain 'In stock'
    expect(find.text('Còn 5 sản phẩm'), findsOneWidget);
  });

  testWidgets('The selected variant cannot be deselected', (tester) async {
    await _pumpPage(
      tester,
      productApi: _FakeProductApi(_product(), [_variant('1', 'Var 1')]),
      cartApi: _FakeCartApi(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Var 1'));
    await tester.pumpAndSettle();

    expect(find.text('Còn 10 sản phẩm'), findsOneWidget);
    expect(find.text('2.900.000 đ'), findsWidgets);
  });

  testWidgets('selects a concrete variant through color and size options', (
    tester,
  ) async {
    final variants = [
      ProductVariant(
        id: '1',
        productId: '9',
        sku: 'WR-39',
        variantName: 'Trắng/Đỏ - 39',
        price: '100000',
        stockQuantity: 5,
        isActive: true,
        option1Name: 'Màu',
        option1Value: 'Trắng/Đỏ',
        option2Name: 'Size',
        option2Value: '39',
      ),
      ProductVariant(
        id: '2',
        productId: '9',
        sku: 'BLACK-40',
        variantName: 'Đen - 40',
        price: '120000',
        stockQuantity: 3,
        isActive: true,
        option1Name: 'Màu',
        option1Value: 'Đen',
        option2Name: 'Size',
        option2Value: '40',
      ),
    ];
    await _pumpPage(
      tester,
      productApi: _FakeProductApi(_product(), variants),
      cartApi: _FakeCartApi(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chọn [Màu]'), findsOneWidget);
    expect(find.text('Chọn [Size]'), findsOneWidget);
    await tester.ensureVisible(find.text('Đen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đen'));
    await tester.pumpAndSettle();

    expect(find.text('40'), findsOneWidget);
    expect(find.text('120.000 đ'), findsWidgets);
    expect(find.text('Còn 3 sản phẩm'), findsOneWidget);
  });

  testWidgets(
    'Add to Cart and Buy Now actions remain available when stock exists',
    (tester) async {
      await _pumpPage(
        tester,
        productApi: _FakeProductApi(_product(), [
          _variant('1', 'Var 1', stock: 10),
        ]),
        cartApi: _FakeCartApi(),
      );
      await tester.pumpAndSettle();

      final addToCartBtn = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton).first,
      );
      final buyNowBtn = tester.widget<FilledButton>(
        find.byType(FilledButton).last,
      );

      expect(addToCartBtn.enabled, isTrue);
      expect(buyNowBtn.enabled, isTrue);
    },
  );

  testWidgets('The page renders at 360px width without overflow', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      productApi: _FakeProductApi(_product(), [_variant('1', 'Var 1')]),
      cartApi: _FakeCartApi(),
      size: const Size(360, 800),
    );
    await tester.pumpAndSettle();

    // If there is an overflow, the test will throw an exception during rendering.
    // If we reach this point, it rendered successfully.
    expect(tester.takeException(), isNull);
  });
}
