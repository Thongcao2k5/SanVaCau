import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/theme/app_theme.dart';

import 'admin_test_accessibility.dart';

import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_product_detail_page.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_product_form_page.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_product_list_page.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_variant_form_page.dart';
import 'package:san_va_cau_app/features/products/data/product_api.dart';
import 'package:san_va_cau_app/features/products/models/product.dart';
import 'package:san_va_cau_app/features/products/models/product_variant.dart';

class FakeProductApi extends ProductApi {
  int createProductCalls = 0;
  int getProductsCallCount = 0;
  String? lastCategoryId;
  String? lastBrandId;

  bool shouldThrow = false;

  final List<Product> mockProducts = [
    Product(
      id: 'p1',
      categoryId: 'c1',
      brandId: 'b1',
      name: 'Product 1',
      description: 'Desc 1',
      imageUrl: 'img1.jpg',
      isActive: true,
      isFeatured: true,
      createdAt: DateTime(2023),
      updatedAt: DateTime(2023),
      category: const ProductCategory(id: 'c1', name: 'Cat 1'),
      brand: const ProductBrand(id: 'b1', name: 'Brand 1'),
    ),
    Product(
      id: 'p2',
      categoryId: 'c1',
      brandId: 'b1',
      name: 'Vợt luyện tập',
      description: 'Sản phẩm thường',
      imageUrl: 'img2.jpg',
      isActive: true,
      isFeatured: false,
      createdAt: DateTime(2023),
      updatedAt: DateTime(2023),
      category: const ProductCategory(id: 'c1', name: 'Cat 1'),
      brand: const ProductBrand(id: 'b1', name: 'Brand 1'),
    ),
  ];

  final List<ProductVariant> mockVariants = [
    const ProductVariant(
      id: 'v1',
      productId: 'p1',
      sku: 'SKU1',
      variantName: 'Variant 1',
      price: '150000',
      isActive: true,
    ),
  ];

  @override
  Future<List<ProductCategory>> getCategories() async => [
    const ProductCategory(id: 'c1', name: 'Cat 1'),
  ];

  @override
  Future<List<ProductBrand>> getBrands() async => [
    const ProductBrand(id: 'b1', name: 'Brand 1'),
  ];

  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? brandId,
  }) async {
    getProductsCallCount++;
    lastCategoryId = categoryId;
    lastBrandId = brandId;
    if (shouldThrow) {
      throw const ApiException(statusCode: 500, message: 'Server Error');
    }
    return mockProducts;
  }

  @override
  Future<Product> getProductById(String id) async =>
      mockProducts.firstWhere((p) => p.id == id);

  @override
  Future<List<ProductVariant>> getProductVariants(String productId) async =>
      mockVariants.where((v) => v.productId == productId).toList();

  @override
  Future<Product> createAdminProduct(Map<String, dynamic> body) async {
    createProductCalls++;
    if (body['name'] == 'Conflict') {
      throw const ApiException(statusCode: 409, message: 'Conflict name');
    }
    return mockProducts.first;
  }

  @override
  Future<Product> updateAdminProduct(
    String id,
    Map<String, dynamic> body,
  ) async {
    return mockProducts.first;
  }

  bool inactivateCalled = false;

  @override
  Future<void> inactivateAdminProduct(String id) async {
    inactivateCalled = true;
  }

  @override
  Future<ProductVariant> createAdminVariant(Map<String, dynamic> body) async {
    if (body['sku'] == 'CONFLICT') {
      throw const ApiException(statusCode: 409, message: 'SKU đã tồn tại');
    }
    return mockVariants.first;
  }

  @override
  Future<ProductVariant> updateAdminVariant(
    String id,
    Map<String, dynamic> body,
  ) async {
    return mockVariants.first;
  }

  @override
  Future<void> inactivateAdminVariant(String id) async {}
}

void main() {
  testWidgets('scrolled product form validates fields above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FakeProductApi();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(viewInsets: const EdgeInsets.only(bottom: 250)),
          child: child!,
        ),
        home: AdminProductFormPage(productApi: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(ElevatedButton),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(
      tester.getBottomRight(find.byType(ElevatedButton)).dy,
      lessThanOrEqualTo(550),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tên sản phẩm'), findsOneWidget);
    expect(api.createProductCalls, 0);
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(320, 800),
    const Size(375, 800),
    const Size(800, 375),
  ]) {
    testWidgets('product pages at $size and text scale 1.5', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = FakeProductApi();
      final pages = [
        AdminProductListPage(isAdmin: true, productApi: api),
        AdminProductDetailPage(productId: 'p1', isAdmin: true, productApi: api),
        AdminProductFormPage(productApi: api),
        AdminVariantFormPage(productId: 'p1', productApi: api),
      ];
      for (var i = 0; i < pages.length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            key: ValueKey(i),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
                viewInsets: i > 1
                    ? const EdgeInsets.only(bottom: 160)
                    : EdgeInsets.zero,
              ),
              child: child!,
            ),
            home: pages[i],
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'page $i');
        await expectAdminAccessibility(tester);
        if (i == 0) {
          await tester.tap(find.byTooltip('Lọc'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('Áp dụng'));
          await tester.tap(find.text('Áp dụng'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        if (find.byType(ListView).evaluate().isNotEmpty) {
          await tester.drag(find.byType(ListView).last, const Offset(0, -2500));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'scrolled page $i');
          await expectAdminAccessibility(tester);
        }
      }
    });
  }
  group('Admin Product Page Tests', () {
    late FakeProductApi productApi;

    setUp(() {
      productApi = FakeProductApi();
    });

    Widget createListWidget(bool isAdmin) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: AdminProductListPage(productApi: productApi, isAdmin: isAdmin),
        ),
      );
    }

    Widget createDetailWidget(bool isAdmin) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: AdminProductDetailPage(
            productId: 'p1',
            productApi: productApi,
            isAdmin: isAdmin,
          ),
        ),
      );
    }

    testWidgets(
      'renders loading state, success, and FAB visibility based on role',
      (tester) async {
        await tester.pumpWidget(createListWidget(false)); // Not admin
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsNothing);

        await tester.pumpAndSettle();
        expect(find.text('Product 1'), findsOneWidget);
        expect(
          find.byType(FloatingActionButton),
          findsNothing,
        ); // BRANCH_MANAGER / STAFF don't see mutation entry

        await tester.pumpWidget(createListWidget(true)); // ADMIN
        await tester.pumpAndSettle();
        expect(
          find.byType(FloatingActionButton),
          findsOneWidget,
        ); // ADMIN sees mutation entry
      },
    );

    testWidgets('error and retry state', (tester) async {
      productApi.shouldThrow = true;
      await tester.pumpWidget(createListWidget(true));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lỗi:'), findsOneWidget);

      productApi.shouldThrow = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Product 1'), findsOneWidget);
    });

    testWidgets('searches locally and filters featured products', (
      tester,
    ) async {
      await tester.pumpWidget(createListWidget(true));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Tìm sản phẩm, danh mục, thương hiệu'),
        'luyện tập',
      );
      await tester.pump();
      expect(find.text('Vợt luyện tập'), findsOneWidget);
      expect(find.text('Product 1'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, 'Tìm sản phẩm, danh mục, thương hiệu'),
        '',
      );
      await tester.pump();
      await tester.tap(find.text('Chỉ sản phẩm nổi bật'));
      await tester.pump();

      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text('Vợt luyện tập'), findsNothing);
    });

    testWidgets(
      'Category and brand filters call the backend and clear filters',
      (tester) async {
        await tester.pumpWidget(createListWidget(true));
        await tester.pumpAndSettle();

        // Open filters
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        expect(find.text('Bộ lọc'), findsOneWidget);

        // Select category
        await tester.tap(
          find.byKey(const Key('admin-product-category-filter')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cat 1').last);
        await tester.pumpAndSettle();

        // Select brand
        await tester.tap(find.byKey(const Key('admin-product-brand-filter')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Brand 1').last);
        await tester.pumpAndSettle();

        // Apply
        await tester.tap(find.text('Áp dụng'));
        await tester.pumpAndSettle();

        expect(productApi.lastCategoryId, 'c1');
        expect(productApi.lastBrandId, 'b1');

        // Clear filters
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xóa bộ lọc'));
        await tester.pumpAndSettle();

        expect(productApi.lastCategoryId, null);
        expect(productApi.lastBrandId, null);
      },
    );

    Widget createFormWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => child),
              ),
              child: const Text('Push'),
            ),
          ),
        ),
      );
    }

    testWidgets('Product create validation and success', (tester) async {
      await tester.pumpWidget(
        createFormWidget(AdminProductFormPage(productApi: productApi)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo sản phẩm'));
      await tester.pump();

      // Validation triggers
      expect(find.text('Vui lòng nhập tên sản phẩm'), findsOneWidget);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'New Product',
      ); // Name
      // Category is dropdown, let's tap it
      await tester.tap(find.text('Danh mục *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cat 1').last);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final submitBtn = find.text('Tạo sản phẩm', skipOffstage: false);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Tạo sản phẩm thành công'), findsOneWidget);
    });

    testWidgets(
      'Product edit pre-filled values and inactivation confirmation',
      (tester) async {
        await tester.pumpWidget(createDetailWidget(true));
        await tester.pumpAndSettle();

        // Product Detail loads variants and product
        expect(find.text('Product 1'), findsOneWidget);
        expect(find.text('Variant 1'), findsOneWidget);
        expect(find.text('SKU: SKU1'), findsOneWidget);

        // Inactivate
        await tester.tap(find.byTooltip('Ẩn'));
        await tester.pumpAndSettle();

        expect(find.text('Ẩn sản phẩm'), findsWidgets); // Dialog
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Ẩn'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Ẩn'));
        await tester.pumpAndSettle();
        // Test we called inactivate
        expect(productApi.inactivateCalled, true);
      },
    );

    testWidgets('Variant create/edit validation and SKU conflict', (
      tester,
    ) async {
      await tester.pumpWidget(
        createFormWidget(
          AdminVariantFormPage(productId: 'p1', productApi: productApi),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final submitBtn = find.byKey(const Key('variant-submit'));
      final formScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        submitBtn,
        300,
        scrollable: formScrollable,
      );
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pump();

      expect(
        find.text('Vui lòng nhập mã SKU', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Vui lòng nhập tên phân loại', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text('Vui lòng nhập giá', skipOffstage: false),
        findsOneWidget,
      );

      await tester.drag(find.byType(ListView).last, const Offset(0, 2000));
      await tester.pumpAndSettle();
      final skuField = find.byKey(const Key('variant-sku'));
      final nameField = find.byKey(const Key('variant-name'));
      final priceField = find.byKey(const Key('variant-price'));
      await tester.scrollUntilVisible(
        skuField,
        -300,
        scrollable: formScrollable,
      );
      await tester.enterText(skuField, 'CONFLICT'); // SKU
      await tester.scrollUntilVisible(
        nameField,
        100,
        scrollable: formScrollable,
      );
      await tester.enterText(nameField, 'V1'); // Name
      await tester.scrollUntilVisible(
        priceField,
        100,
        scrollable: formScrollable,
      );
      await tester.enterText(priceField, '150.5'); // Price
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        submitBtn,
        300,
        scrollable: formScrollable,
      );
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('SKU đã tồn tại', skipOffstage: false),
        findsOneWidget,
      ); // Backend error

      await tester.drag(find.byType(ListView).last, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        skuField,
        -300,
        scrollable: formScrollable,
      );
      await tester.enterText(skuField, 'SKU2'); // Good SKU
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        submitBtn,
        300,
        scrollable: formScrollable,
      );
      await tester.ensureVisible(submitBtn);
      await tester.pumpAndSettle();
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Tạo phân loại thành công', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('Variant inactivation confirmation', (tester) async {
      await tester.pumpWidget(createDetailWidget(true));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ẩn phân loại'));
      await tester.pumpAndSettle();

      expect(
        find.text('Bạn có chắc chắn muốn ẩn phân loại "Variant 1" không?'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(TextButton, 'Ẩn'));
      await tester.pumpAndSettle();

      expect(find.text('Đã ẩn phân loại'), findsOneWidget);
    });
  });
}
