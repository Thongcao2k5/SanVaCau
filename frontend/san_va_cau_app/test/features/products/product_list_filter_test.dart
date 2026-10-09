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

    // Initial state: "Tất cả sản phẩm" and "1 sản phẩm"
    expect(find.text('Tất cả sản phẩm'), findsOneWidget);
    expect(find.text('1 sản phẩm'), findsOneWidget);

    // Select category
    await tester.tap(find.widgetWithText(ChoiceChip, 'Vợt cầu lông'));
    await tester.pumpAndSettle();

    expect(api.requests, hasLength(2));
    expect(api.requests.last.categoryId, '2');
    expect(api.requests.last.brandId, isNull);

    // Header should now show "Vợt cầu lông"
    // (There is also the ChoiceChip with the same text, so findsWidgets)
    expect(find.text('Vợt cầu lông'), findsWidgets);

    // Select brand
    await tester.tap(find.widgetWithText(ChoiceChip, 'Yonex'));
    await tester.pumpAndSettle();

    expect(api.requests, hasLength(3));
    expect(api.requests.last.categoryId, '2');
    expect(api.requests.last.brandId, '4');

    // Clear category using "Tất cả"
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
    await tester.pumpAndSettle();

    expect(api.requests, hasLength(4));
    expect(api.requests.last.categoryId, isNull);
    expect(api.requests.last.brandId, '4');
    expect(find.text('Tất cả sản phẩm'), findsOneWidget);

    // Clear brand using "Tất cả hãng"
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả hãng'));
    await tester.pumpAndSettle();

    expect(api.requests, hasLength(5));
    expect(api.requests.last.categoryId, isNull);
    expect(api.requests.last.brandId, isNull);
  });

  testWidgets('shows empty state when no product matches and clears filters', (
    tester,
  ) async {
    final api = _EmptyProductApi();
    await tester.pumpWidget(
      MaterialApp(home: ProductListPage(productApi: api)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa có sản phẩm'), findsOneWidget);

    // Select category
    await tester.tap(find.widgetWithText(ChoiceChip, 'Vợt cầu lông'));
    await tester.pumpAndSettle();

    // Expect filter-specific empty state
    expect(find.text('Không tìm thấy sản phẩm'), findsOneWidget);
    expect(find.text('Xóa bộ lọc'), findsOneWidget);

    // Tap "Xóa bộ lọc"
    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pumpAndSettle();

    expect(api.requests.last.categoryId, isNull);
  });

  testWidgets('shows filter error and retries loading filter options', (
    tester,
  ) async {
    final api = _FailingFilterApi();
    await tester.pumpWidget(
      MaterialApp(home: ProductListPage(productApi: api)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể tải bộ lọc'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(api.categoryAttempts, 2);
    expect(find.widgetWithText(ChoiceChip, 'Vợt cầu lông'), findsOneWidget);
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

class _FailingFilterApi extends _FakeProductApi {
  var categoryAttempts = 0;

  @override
  Future<List<ProductCategory>> getCategories() async {
    categoryAttempts++;
    if (categoryAttempts == 1) throw Exception('filter failed');
    return super.getCategories();
  }
}
