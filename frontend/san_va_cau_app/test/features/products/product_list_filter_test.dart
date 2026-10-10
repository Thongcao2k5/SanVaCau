import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/products/data/product_api.dart';
import 'package:san_va_cau_app/features/products/models/product.dart';
import 'package:san_va_cau_app/features/products/pages/product_list_page.dart';

class _ProductRequest {
  const _ProductRequest(this.categoryId, this.brandId);

  final String? categoryId;
  final String? brandId;
}

class _FakeProductApi extends ProductApi {
  final requests = <_ProductRequest>[];

  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? brandId,
  }) async {
    requests.add(_ProductRequest(categoryId, brandId));
    return [_product()];
  }

  @override
  Future<List<ProductCategory>> getCategories() async => const [
    ProductCategory(id: '2', name: 'Vợt cầu lông'),
    ProductCategory(id: '3', name: 'Giày cầu lông'),
  ];

  @override
  Future<List<ProductBrand>> getBrands() async => const [
    ProductBrand(id: '4', name: 'Yonex'),
    ProductBrand(id: '5', name: 'Victor'),
  ];
}

Product _product() {
  return Product(
    id: '9',
    categoryId: '2',
    brandId: '4',
    name: 'Yonex Astrox',
    isActive: true,
    isFeatured: false,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
    category: const ProductCategory(id: '2', name: 'Vợt cầu lông'),
    brand: const ProductBrand(id: '4', name: 'Yonex'),
  );
}

void main() {
  testWidgets('empty search remains scrollable with keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(home: ProductListPage(productApi: _FakeProductApi())),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '😀');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy sản phẩm'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('searches products and clears the search', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ProductListPage(productApi: _FakeProductApi())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byTooltip('Giỏ hàng'), findsOneWidget);
    expect(find.text('VỢT CẦU LÔNG'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'không tồn tại');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy sản phẩm'), findsOneWidget);
    await tester.tap(find.byTooltip('Xóa tìm kiếm'));
    await tester.pumpAndSettle();
    expect(find.text('Yonex Astrox'), findsOneWidget);
    await tester.tap(find.text('Xem thêm'));
    await tester.pumpAndSettle();
    expect(find.text('Xem thêm'), findsNothing);
    expect(find.text('Vợt cầu lông'), findsWidgets);
    await tester.tap(find.byTooltip('Tất cả sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.text('Xem thêm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
