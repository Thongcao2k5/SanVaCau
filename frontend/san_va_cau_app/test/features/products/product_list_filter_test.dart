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
  testWidgets('applies category and brand filters then clears them', (
    tester,
  ) async {
    final api = _FakeProductApi();
    await tester.pumpWidget(
      MaterialApp(home: ProductListPage(productApi: api)),
    );
    await tester.pumpAndSettle();

    expect(api.requests, hasLength(1));
    expect(api.requests.single.categoryId, isNull);
    expect(api.requests.single.brandId, isNull);

    await tester.tap(find.byTooltip('Lọc sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.text('Bộ lọc sản phẩm'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Vợt cầu lông'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Yonex'));
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();

    expect(api.requests, hasLength(2));
    expect(api.requests.last.categoryId, '2');
    expect(api.requests.last.brandId, '4');
    expect(find.text('Vợt cầu lông • Yonex'), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa bộ lọc'));
    await tester.pumpAndSettle();

    expect(api.requests, hasLength(3));
    expect(api.requests.last.categoryId, isNull);
    expect(api.requests.last.brandId, isNull);
    expect(find.text('Vợt cầu lông • Yonex'), findsNothing);
  });

  testWidgets('keeps filter options reachable when no product matches', (
    tester,
  ) async {
    final api = _EmptyProductApi();
    await tester.pumpWidget(
      MaterialApp(home: ProductListPage(productApi: api)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có sản phẩm'), findsOneWidget);
    expect(find.byTooltip('Lọc sản phẩm'), findsOneWidget);
  });
}

class _EmptyProductApi extends _FakeProductApi {
  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? brandId,
  }) async {
    requests.add(_ProductRequest(categoryId, brandId));
    return [];
  }
}
