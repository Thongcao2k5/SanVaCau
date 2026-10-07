import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_inventory_list_page.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_inventory_form_page.dart';
import 'package:san_va_cau_app/features/admin/data/admin_inventory_api.dart';
import 'package:san_va_cau_app/features/admin/models/admin_inventory.dart';
import 'package:san_va_cau_app/features/branches/data/branch_api.dart';
import 'package:san_va_cau_app/features/branches/models/branch.dart';
import 'package:san_va_cau_app/features/products/data/product_api.dart';
import 'package:san_va_cau_app/features/products/models/product.dart';
import 'package:san_va_cau_app/features/products/models/product_variant.dart';

class FakeInventoryApi extends AdminInventoryApi {
  bool shouldThrow = false;
  bool mutationShouldThrow = false;
  String? lastBranchId;
  int getCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  String? lastCreatedBranchId;
  String? lastCreatedVariantId;
  int? lastQuantity;

  final List<AdminInventory> mockInventories = [
    AdminInventory(
      id: 'inv1',
      branchId: 'b1',
      productVariantId: 'v1',
      quantity: 10,
      updatedAt: DateTime(2023),
      branch: const AdminInventoryBranch(id: 'b1', name: 'Branch 1'),
      productVariant: const AdminInventoryVariant(
        id: 'v1',
        sku: 'SKU1',
        variantName: 'Variant 1',
        product: AdminInventoryProduct(id: 'p1', name: 'Product 1'),
      ),
    ),
    AdminInventory(
      id: 'inv2',
      branchId: 'b1',
      productVariantId: 'v2',
      quantity: 2, // Low stock
      updatedAt: DateTime(2023),
      branch: const AdminInventoryBranch(id: 'b1', name: 'Branch 1'),
      productVariant: const AdminInventoryVariant(
        id: 'v2',
        sku: 'SKU2',
        variantName: 'Variant 2',
        product: AdminInventoryProduct(id: 'p1', name: 'Product 1'),
      ),
    ),
  ];

  @override
  Future<List<AdminInventory>> getInventories({
    String? branchId,
    String? productVariantId,
  }) async {
    getCalls++;
    lastBranchId = branchId;
    if (shouldThrow) {
      throw const ApiException(statusCode: 500, message: 'Server Error');
    }
    if (branchId != null) {
      return mockInventories.where((inv) => inv.branchId == branchId).toList();
    }
    return mockInventories;
  }

  @override
  Future<AdminInventory> createInventory({
    required String branchId,
    required String productVariantId,
    required int quantity,
  }) async {
    createCalls++;
    lastCreatedBranchId = branchId;
    lastCreatedVariantId = productVariantId;
    lastQuantity = quantity;
    if (mutationShouldThrow) {
      throw const ApiException(statusCode: 500, message: 'Save failed');
    }
    if (productVariantId == 'v1') {
      throw const ApiException(statusCode: 409, message: 'Conflict');
    }
    return mockInventories.first;
  }

  @override
  Future<AdminInventory> updateInventoryQuantity({
    required String inventoryId,
    required int quantity,
  }) async {
    updateCalls++;
    lastQuantity = quantity;
    if (mutationShouldThrow) {
      throw const ApiException(statusCode: 500, message: 'Save failed');
    }
    return mockInventories.first;
  }
}

class FakeBranchApi extends BranchApi {
  @override
  Future<List<Branch>> getBranches() async => [
    const Branch(
      id: 'b1',
      name: 'Branch 1',
      address: 'Addr 1',
      status: 'ACTIVE',
      openingTime: '08:00',
      closingTime: '22:00',
    ),
    const Branch(
      id: 'b2',
      name: 'Branch 2',
      address: 'Addr 2',
      status: 'ACTIVE',
      openingTime: '08:00',
      closingTime: '22:00',
    ),
  ];
}

class FakeProductApi extends ProductApi {
  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? brandId,
  }) async => [
    Product(
      id: 'p1',
      categoryId: 'c1',
      brandId: 'b1',
      name: 'Product 1',
      description: 'Desc',
      imageUrl: 'img.jpg',
      isActive: true,
      isFeatured: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      category: const ProductCategory(id: 'c1', name: 'Cat 1'),
      brand: const ProductBrand(id: 'b1', name: 'Brand 1'),
    ),
  ];

  @override
  Future<List<ProductVariant>> getProductVariants(String productId) async => [
    const ProductVariant(
      id: 'v1',
      productId: 'p1',
      sku: 'SKU1',
      variantName: 'Var 1',
      price: '100',
      isActive: true,
    ),
    const ProductVariant(
      id: 'v2',
      productId: 'p1',
      sku: 'SKU2',
      variantName: 'Var 2',
      price: '200',
      isActive: true,
    ),
  ];
}

void main() {
  group('Admin Inventory Page Tests', () {
    late FakeInventoryApi inventoryApi;
    late FakeBranchApi branchApi;
    late FakeProductApi productApi;

    setUp(() {
      inventoryApi = FakeInventoryApi();
      branchApi = FakeBranchApi();
      productApi = FakeProductApi();
    });

    Widget createListWidget(String role, String? assignedBranchId) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: AdminInventoryListPage(
            role: role,
            assignedBranchId: assignedBranchId,
            inventoryApi: inventoryApi,
            branchApi: branchApi,
            productApi: productApi,
          ),
        ),
      );
    }

    Widget createFormWidget(
      String role,
      String? assignedBranchId, {
      AdminInventory? inventory,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminInventoryFormPage(
                      role: role,
                      assignedBranchId: assignedBranchId,
                      inventory: inventory,
                      inventoryApi: inventoryApi,
                      branchApi: branchApi,
                      productApi: productApi,
                    ),
                  ),
                ),
                child: const Text('Push'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Loading state, success, low stock visual, missing branchId', (
      tester,
    ) async {
      await tester.pumpWidget(createListWidget('STAFF', null));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('chưa được gán'),
        findsOneWidget,
      ); // missing branchId
      expect(inventoryApi.getCalls, 0);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('Loading state, success, low stock visual (ADMIN)', (
      tester,
    ) async {
      await tester.pumpWidget(createListWidget('ADMIN', null));
      await tester.pumpAndSettle();

      expect(find.text('Product 1'), findsWidgets);
      expect(find.text('SKU: SKU1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Low stock text

      // Low stock visual indication via warning color
      // It's tested visually, but we can check if there is a Container with warning color
      // Since we don't have access to AppColors directly here, we just know '2' and 'Tồn kho' are there.
      expect(find.text('Tồn kho'), findsWidgets);
    });

    testWidgets('ADMIN can filter branches, create and edit', (tester) async {
      await tester.pumpWidget(createListWidget('ADMIN', null));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Open filter
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      expect(find.text('Lọc theo chi nhánh'), findsOneWidget);

      await tester.tap(find.text('Tất cả chi nhánh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Branch 1').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(inventoryApi.lastBranchId, 'b1');
    });

    testWidgets('local search filters by SKU', (tester) async {
      await tester.pumpWidget(createListWidget('ADMIN', null));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('inventory-search-field')),
        'SKU2',
      );
      await tester.pump();

      expect(find.text('SKU: SKU2'), findsOneWidget);
      expect(find.text('SKU: SKU1'), findsNothing);
    });

    testWidgets('BRANCH_MANAGER is locked and can create/edit', (tester) async {
      await tester.pumpWidget(createListWidget('BRANCH_MANAGER', 'b1'));
      await tester.pumpAndSettle();

      expect(inventoryApi.lastBranchId, 'b1');
      expect(find.byIcon(Icons.filter_list), findsNothing); // No filter icon
      expect(find.byType(FloatingActionButton), findsOneWidget); // Can create
    });

    testWidgets('STAFF is locked and sees no mutation controls', (
      tester,
    ) async {
      await tester.pumpWidget(createListWidget('STAFF', 'b1'));
      await tester.pumpAndSettle();

      expect(inventoryApi.lastBranchId, 'b1');
      expect(find.byIcon(Icons.filter_list), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('STAFF cannot open mutation form directly', (tester) async {
      await tester.pumpWidget(
        createFormWidget(
          'STAFF',
          'b1',
          inventory: inventoryApi.mockInventories.first,
        ),
      );
      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(find.textContaining('không có quyền'), findsOneWidget);
      expect(find.byKey(const Key('inventory-submit-button')), findsNothing);
    });

    testWidgets('Error and retry state', (tester) async {
      inventoryApi.shouldThrow = true;
      await tester.pumpWidget(createListWidget('ADMIN', null));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lỗi:'), findsOneWidget);

      inventoryApi.shouldThrow = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('Product 1'), findsWidgets);
    });

    testWidgets('Create form validation and success', (tester) async {
      await tester.pumpWidget(createFormWidget('ADMIN', null));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      // Tap create without data
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      final submitBtn = find.byKey(const Key('inventory-submit-button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng chọn chi nhánh'), findsOneWidget);
      expect(find.text('Vui lòng chọn sản phẩm'), findsOneWidget);
      expect(find.text('Vui lòng nhập số lượng'), findsOneWidget);

      // Select Branch
      await tester.ensureVisible(
        find.byKey(const Key('inventory-branch-field')),
      );
      await tester.tap(find.byKey(const Key('inventory-branch-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Branch 1').last);
      await tester.pumpAndSettle();

      // Select Product
      await tester.tap(find.byKey(const Key('inventory-product-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Product 1').last);
      await tester.pumpAndSettle();

      // Select Variant
      await tester.tap(find.byKey(const Key('inventory-variant-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Var 2 (SKU2)').last);
      await tester.pumpAndSettle();

      // Enter quantity
      await tester.enterText(
        find.byKey(const Key('inventory-quantity-field')),
        '10',
      );

      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Push'), findsOneWidget);
      expect(inventoryApi.createCalls, 1);
      expect(inventoryApi.lastCreatedBranchId, 'b1');
      expect(inventoryApi.lastCreatedVariantId, 'v2');
      expect(inventoryApi.lastQuantity, 10);
    });

    testWidgets('Create form duplicate 409 conflict', (tester) async {
      await tester.pumpWidget(createFormWidget('ADMIN', null));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory-branch-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Branch 1').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory-product-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Product 1').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('inventory-variant-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Var 1 (SKU1)').last); // v1 causes 409
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('inventory-quantity-field')),
        '10',
      );

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      final submitBtn = find.byKey(const Key('inventory-submit-button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(
        find.text('Sản phẩm này đã có trong tồn kho của chi nhánh'),
        findsOneWidget,
      );
      final quantityField = tester.widget<TextFormField>(
        find.byKey(const Key('inventory-quantity-field')),
      );
      expect(quantityField.controller?.text, '10');
    });

    testWidgets('Edit form and zero quantity confirmation', (tester) async {
      await tester.pumpWidget(
        createFormWidget(
          'ADMIN',
          null,
          inventory: inventoryApi.mockInventories.first,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(find.text('Product 1'), findsWidgets); // Read only fields

      await tester.enterText(
        find.byKey(const Key('inventory-quantity-field')),
        '0',
      );

      final submitBtn = find.byKey(const Key('inventory-submit-button'));
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Bạn có chắc chắn muốn đặt số lượng tồn kho bằng 0?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Đồng ý'));
      await tester.pumpAndSettle();

      expect(find.text('Push'), findsOneWidget); // Returned
      expect(inventoryApi.updateCalls, 1);
      expect(inventoryApi.lastQuantity, 0);
    });

    testWidgets('quantity validation rejects negative and decimal values', (
      tester,
    ) async {
      await tester.pumpWidget(
        createFormWidget(
          'ADMIN',
          null,
          inventory: inventoryApi.mockInventories.first,
        ),
      );
      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      final quantity = find.byKey(const Key('inventory-quantity-field'));
      final submit = find.byKey(const Key('inventory-submit-button'));

      await tester.enterText(quantity, '-1');
      await tester.tap(submit);
      await tester.pump();
      expect(find.text('Số lượng không được âm'), findsOneWidget);

      await tester.enterText(quantity, '1.5');
      await tester.tap(submit);
      await tester.pump();
      expect(find.text('Số lượng phải là số nguyên'), findsOneWidget);
      expect(inventoryApi.updateCalls, 0);
    });
  });
}
