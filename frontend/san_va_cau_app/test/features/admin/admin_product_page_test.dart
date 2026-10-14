import 'dart:async';

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
  int createVariantCalls = 0;
  Map<String, dynamic>? lastProductBody;
  Map<String, dynamic>? lastVariantBody;
  String? updatedProductId;
  String? updatedVariantId;
  Completer<Product>? pendingProduct;
  Completer<ProductVariant>? pendingVariant;
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
    lastProductBody = Map.of(body);
    if (pendingProduct != null) return pendingProduct!.future;
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
    updatedProductId = id;
    lastProductBody = Map.of(body);
    return mockProducts.first;
  }

  bool inactivateCalled = false;

  @override
  Future<void> inactivateAdminProduct(String id) async {
    inactivateCalled = true;
  }

  @override
  Future<ProductVariant> createAdminVariant(Map<String, dynamic> body) async {
    createVariantCalls++;
    lastVariantBody = Map.of(body);
    if (pendingVariant != null) return pendingVariant!.future;
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
    updatedVariantId = id;
    lastVariantBody = Map.of(body);
    return mockVariants.first;
  }

  @override
  Future<void> inactivateAdminVariant(String id) async {}
}

void main() {
  for (final detail in [false, true]) {
    for (final source in [
      'assets/demo/product-shoes.jpg',
      '/uploads/product.png',
      'https://example.com/product.png',
      '',
      null,
    ]) {
      testWidgets(
        '${detail ? 'detail and variant' : 'list'} images support $source',
        (tester) async {
          final api = FakeProductApi();
          api.mockProducts
            ..clear()
            ..add(
              Product.fromJson({
                'id': 'p1',
                'name': 'Image product',
                'categoryId': 'c1',
                'category': {'id': 'c1', 'name': 'Cat 1'},
                'imageUrl': source,
                'isActive': true,
                'isFeatured': false,
              }),
            );
          api.mockVariants
            ..clear()
            ..add(
              ProductVariant(
                id: 'v1',
                productId: 'p1',
                sku: 'SKU1',
                variantName: 'Image variant',
                price: '150000',
                imageUrl: source,
                isActive: true,
              ),
            );
          await tester.pumpWidget(
            MaterialApp(
              home: detail
                  ? AdminProductDetailPage(productId: 'p1', productApi: api)
                  : AdminProductListPage(productApi: api),
            ),
          );
          // Inspect the provider before network-error fallback replaces the image.
          await tester.pump();
          final images = tester.widgetList<Image>(find.byType(Image)).toList();
          if (source == null || source.isEmpty) {
            expect(images, isEmpty);
            expect(find.byIcon(Icons.inventory_2_rounded), findsOneWidget);
            if (detail) {
              expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
            }
          } else {
            expect(images, hasLength(detail ? 2 : 1));
            for (final image in images) {
              expect(image.fit, BoxFit.cover);
              if (source.startsWith('assets/')) {
                expect(image.image, isA<AssetImage>());
                expect((image.image as AssetImage).assetName, source);
              } else {
                expect(image.image, isA<NetworkImage>());
                final url = (image.image as NetworkImage).url;
                expect(url, source.startsWith('/') ? endsWith(source) : source);
                expect(Uri.parse(url).hasScheme, isTrue);
              }
            }
          }
          await tester.pumpAndSettle();
          if (source != null && source.startsWith('assets/')) {
            expect(find.byIcon(Icons.hide_image_rounded), findsNothing);
          } else if (source != null && source.isNotEmpty) {
            expect(
              find.byIcon(Icons.hide_image_rounded),
              findsNWidgets(detail ? 2 : 1),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
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
      await tester.tap(find.text('Sản phẩm nổi bật'));
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
        await tester.tap(find.byIcon(Icons.tune_rounded).first);
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
        await tester.tap(find.byIcon(Icons.tune_rounded).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Xóa bộ lọc'));
        await tester.pumpAndSettle();

        expect(productApi.lastCategoryId, null);
        expect(productApi.lastBrandId, null);
      },
    );

    testWidgets('list opens detail and refreshes after product is hidden', (
      tester,
    ) async {
      await tester.pumpWidget(createListWidget(true));
      await tester.pumpAndSettle();
      expect(productApi.getProductsCallCount, 1);

      await tester.tap(find.text('Product 1'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết sản phẩm'), findsOneWidget);
      expect(find.text('Variant 1'), findsOneWidget);

      await tester.tap(find.byTooltip('Ẩn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(productApi.inactivateCalled, false);

      await tester.tap(find.byTooltip('Ẩn'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Ẩn'));
      await tester.pumpAndSettle();

      expect(productApi.inactivateCalled, true);
      expect(productApi.getProductsCallCount, 2);
      expect(find.text('Quản lý sản phẩm'), findsOneWidget);
    });

    testWidgets('non-admin detail remains read-only', (tester) async {
      await tester.pumpWidget(createDetailWidget(false));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Sửa'), findsNothing);
      expect(find.byTooltip('Ẩn'), findsNothing);
      expect(find.text('Thêm mới'), findsNothing);
      expect(find.byTooltip('Thao tác phân loại'), findsNothing);
      expect(find.text('Đang hoạt động'), findsWidgets);
      expect(find.text('Nổi bật'), findsOneWidget);
    });

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

      await tester.ensureVisible(find.byKey(const Key('product-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo sản phẩm'));
      await tester.pump();

      // Validation triggers
      expect(find.text('Vui lòng nhập tên sản phẩm'), findsOneWidget);
      expect(find.text('Vui lòng chọn danh mục'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('product-name')));
      await tester.pumpAndSettle();
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
      expect(productApi.lastProductBody, {
        'name': 'New Product',
        'categoryId': 'c1',
        'brandId': null,
        'description': null,
        'imageUrl': null,
        'isFeatured': false,
      });
    });

    for (final isVariant in [false, true]) {
      for (final source in [
        'assets/demo/product-shoes.jpg',
        '/uploads/product.png',
        'http://example.com/image.jpg',
        'https://example.com/image.jpg',
      ]) {
        testWidgets(
          '${isVariant ? 'variant' : 'product'} edit preserves existing image $source',
          (tester) async {
            final product = Product.fromJson({
              'id': 'p1',
              'categoryId': 'c1',
              'name': 'Existing product',
              'category': {'id': 'c1', 'name': 'Cat 1'},
              'imageUrl': source,
              'isActive': true,
              'isFeatured': false,
            });
            final variant = ProductVariant(
              id: 'v1',
              productId: 'p1',
              sku: 'SKU1',
              variantName: 'Existing variant',
              price: '150000',
              imageUrl: source,
              isActive: true,
            );
            await tester.pumpWidget(
              createFormWidget(
                isVariant
                    ? AdminVariantFormPage(
                        productId: 'p1',
                        variant: variant,
                        productApi: productApi,
                      )
                    : AdminProductFormPage(
                        product: product,
                        productApi: productApi,
                      ),
              ),
            );
            await tester.tap(find.text('Push'));
            await tester.pumpAndSettle();
            final image = find.byKey(
              Key(isVariant ? 'variant-image-url' : 'product-image-url'),
            );
            final submit = find.byKey(
              Key(isVariant ? 'variant-submit' : 'product-submit'),
            );
            await tester.ensureVisible(image);
            await tester.pumpAndSettle();
            expect(
              tester.widget<TextFormField>(image).controller!.text,
              source,
            );
            await tester.enterText(image, 'invalid-image');
            await tester.ensureVisible(submit);
            await tester.pumpAndSettle();
            await tester.tap(submit);
            await tester.pumpAndSettle();
            expect(
              find.text('URL không hợp lệ', skipOffstage: false),
              findsOneWidget,
            );
            expect(productApi.updatedProductId, isNull);
            expect(productApi.updatedVariantId, isNull);
            await tester.ensureVisible(image);
            await tester.pumpAndSettle();
            await tester.enterText(image, source);
            await tester.ensureVisible(submit);
            await tester.pumpAndSettle();
            await tester.tap(submit);
            await tester.pumpAndSettle();
            expect(
              isVariant
                  ? productApi.updatedVariantId
                  : productApi.updatedProductId,
              isVariant ? 'v1' : 'p1',
            );
            expect(
              (isVariant
                  ? productApi.lastVariantBody
                  : productApi.lastProductBody)!['imageUrl'],
              source,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
      testWidgets(
        '${isVariant ? 'variant' : 'product'} rejects unsupported image sources without update',
        (tester) async {
          await tester.pumpWidget(
            createFormWidget(
              isVariant
                  ? AdminVariantFormPage(
                      productId: 'p1',
                      variant: productApi.mockVariants.first,
                      productApi: productApi,
                    )
                  : AdminProductFormPage(
                      product: productApi.mockProducts.first,
                      productApi: productApi,
                    ),
            ),
          );
          await tester.tap(find.text('Push'));
          await tester.pumpAndSettle();
          final image = find.byKey(
            Key(isVariant ? 'variant-image-url' : 'product-image-url'),
          );
          final submit = find.byKey(
            Key(isVariant ? 'variant-submit' : 'product-submit'),
          );
          for (final source in [
            'invalid-image',
            'assets/',
            '/',
            '//example.com/image.jpg',
            'assets/../image.jpg',
            'javascript:alert(1)',
            'file:///image.jpg',
            'https:///image.jpg',
          ]) {
            await tester.ensureVisible(image);
            await tester.pumpAndSettle();
            await tester.enterText(image, source);
            await tester.ensureVisible(submit);
            await tester.pumpAndSettle();
            await tester.tap(submit);
            await tester.pumpAndSettle();
            expect(
              find.text('URL không hợp lệ', skipOffstage: false),
              findsOneWidget,
              reason: source,
            );
            expect(productApi.updatedProductId, isNull, reason: source);
            expect(productApi.updatedVariantId, isNull, reason: source);
          }
          expect(tester.takeException(), isNull);
        },
      );
      testWidgets(
        '${isVariant ? 'variant' : 'product'} form locks pending save and preserves payload',
        (tester) async {
          if (isVariant) {
            productApi.pendingVariant = Completer<ProductVariant>();
          } else {
            productApi.pendingProduct = Completer<Product>();
          }
          Object? returned;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async {
                      returned = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => isVariant
                              ? AdminVariantFormPage(
                                  productId: 'p1',
                                  productApi: productApi,
                                )
                              : AdminProductFormPage(productApi: productApi),
                        ),
                      );
                    },
                    child: const Text('Open form'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open form'));
          await tester.pumpAndSettle();
          Future<void> enter(String key, String value) async {
            final field = find.byKey(Key(key));
            await tester.ensureVisible(field);
            await tester.pumpAndSettle();
            await tester.enterText(field, value);
          }

          if (isVariant) {
            await enter('variant-sku', ' SKU2 ');
            await enter('variant-name', ' White 40 ');
            await enter('variant-price', '150.5');
          } else {
            await enter('product-name', ' New product ');
            await tester.tap(find.byKey(const Key('product-category')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Cat 1').last);
            await tester.pumpAndSettle();
            await tester.ensureVisible(
              find.byKey(const Key('product-featured')),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byType(Switch));
          }
          final submit = find.byKey(
            Key(isVariant ? 'variant-submit' : 'product-submit'),
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            submit,
            250,
            scrollable: find.byType(Scrollable).last,
          );
          await tester.ensureVisible(submit);
          await tester.pumpAndSettle();
          await tester.tap(submit);
          await tester.tap(submit);
          await tester.pump();
          expect(
            isVariant
                ? productApi.createVariantCalls
                : productApi.createProductCalls,
            1,
          );
          expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
          for (final field in tester.widgetList<TextFormField>(
            find.byType(TextFormField),
          )) {
            expect(field.enabled, false);
          }
          expect(find.text('Đang lưu…'), findsOneWidget);
          if (isVariant) {
            expect(productApi.lastVariantBody, {
              'productId': 'p1',
              'sku': 'SKU2',
              'variantName': 'White 40',
              'price': 150.5,
              'imageUrl': null,
              'option1Name': null,
              'option1Value': null,
              'option2Name': null,
              'option2Value': null,
            });
            productApi.pendingVariant!.complete(productApi.mockVariants.first);
          } else {
            expect(productApi.lastProductBody, {
              'categoryId': 'c1',
              'brandId': null,
              'name': 'New product',
              'description': null,
              'imageUrl': null,
              'isFeatured': true,
            });
            productApi.pendingProduct!.complete(productApi.mockProducts.first);
          }
          await tester.pumpAndSettle();
          expect(returned, isVariant ? productApi.mockVariants.first : true);
        },
      );

      testWidgets(
        '${isVariant ? 'variant' : 'product'} edit keeps defaults and rejects invalid image URL',
        (tester) async {
          await tester.pumpWidget(
            createFormWidget(
              isVariant
                  ? AdminVariantFormPage(
                      productId: 'p1',
                      variant: productApi.mockVariants.first,
                      productApi: productApi,
                    )
                  : AdminProductFormPage(
                      product: productApi.mockProducts.first,
                      productApi: productApi,
                    ),
            ),
          );
          await tester.tap(find.text('Push'));
          await tester.pumpAndSettle();
          final nameKey = Key(isVariant ? 'variant-name' : 'product-name');
          expect(
            tester.widget<TextFormField>(find.byKey(nameKey)).controller!.text,
            isVariant ? 'Variant 1' : 'Product 1',
          );
          final image = find.byKey(
            Key(isVariant ? 'variant-image-url' : 'product-image-url'),
          );
          await tester.ensureVisible(image);
          await tester.pumpAndSettle();
          await tester.enterText(image, 'invalid-image');
          final submit = find.byKey(
            Key(isVariant ? 'variant-submit' : 'product-submit'),
          );
          await tester.ensureVisible(submit);
          await tester.pumpAndSettle();
          await tester.tap(submit);
          await tester.pumpAndSettle();
          expect(
            find.text('URL không hợp lệ', skipOffstage: false),
            findsOneWidget,
          );
          expect(productApi.updatedProductId, isNull);
          expect(productApi.updatedVariantId, isNull);
          await tester.ensureVisible(image);
          await tester.pumpAndSettle();
          await tester.enterText(image, 'https://example.com/product.jpg');
          await tester.ensureVisible(submit);
          await tester.pumpAndSettle();
          await tester.tap(submit);
          await tester.pumpAndSettle();
          if (isVariant) {
            expect(productApi.updatedVariantId, 'v1');
            expect(productApi.lastVariantBody!['price'], 150000.0);
            expect(productApi.lastVariantBody!['sku'], 'SKU1');
          } else {
            expect(productApi.updatedProductId, 'p1');
            expect(productApi.lastProductBody!['isFeatured'], true);
            expect(productApi.lastProductBody!['categoryId'], 'c1');
            expect(productApi.lastProductBody!['brandId'], 'b1');
          }
        },
      );
    }

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
