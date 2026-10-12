import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/theme/app_theme.dart';

import 'admin_test_accessibility.dart';

import 'package:san_va_cau_app/features/admin/pages/admin_branch_list_page.dart';
import 'package:san_va_cau_app/features/branches/data/branch_api.dart';
import 'package:san_va_cau_app/features/branches/models/branch.dart';

const _branch = Branch(
  id: '1',
  name: 'Chi nhánh Trung tâm',
  address: 'Quận 1',
  openingTime: '06:00',
  closingTime: '22:00',
  status: 'ACTIVE',
  isFeatured: false,
  sortOrder: 0,
);

class _FakeBranchApi extends BranchApi {
  bool? savedFeatured;
  int? savedSortOrder;
  var inactivateCalls = 0;
  var createCalls = 0;

  @override
  Future<List<Branch>> getBranches() async => const [_branch];

  @override
  Future<Branch> updateBranch(
    String id, {
    String? name,
    String? address,
    String? phone,
    String? description,
    String? openingTime,
    String? closingTime,
    String? imageUrl,
    bool? isFeatured,
    int? sortOrder,
  }) async {
    savedFeatured = isFeatured;
    savedSortOrder = sortOrder;
    return _branch;
  }

  @override
  Future<void> inactivateBranch(String id) async {
    inactivateCalls += 1;
  }

  @override
  Future<Branch> createBranch({
    required String name,
    required String address,
    required String openingTime,
    required String closingTime,
    String? phone,
    String? description,
  }) async {
    createCalls += 1;
    return _branch;
  }
}

void main() {
  for (final size in [
    const Size(320, 800),
    const Size(375, 800),
    const Size(800, 375),
  ]) {
    testWidgets('branch list and settings at $size with large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: AdminBranchListPage(branchApi: _FakeBranchApi()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectAdminAccessibility(tester);
      await tester.tap(find.text(_branch.name));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectAdminAccessibility(tester);
      await tester.drag(find.byType(ListView).last, const Offset(0, -2500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectAdminAccessibility(tester);
    });
  }
  testWidgets('updates featured state and home sort order', (tester) async {
    _useTallView(tester);
    final api = _FakeBranchApi();
    await tester.pumpWidget(
      MaterialApp(home: AdminBranchListPage(branchApi: api)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chi nhánh Trung tâm'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Chi nhánh nổi bật'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Chi nhánh nổi bật'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Thứ tự hiển thị'),
      '3',
    );
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(api.savedFeatured, true);
    expect(api.savedSortOrder, 3);
  });

  testWidgets('confirms before inactivating a branch', (tester) async {
    _useTallView(tester);
    final api = _FakeBranchApi();
    await tester.pumpWidget(
      MaterialApp(home: AdminBranchListPage(branchApi: api)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chi nhánh Trung tâm'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ngừng hoạt động chi nhánh'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Ngừng hoạt động chi nhánh'));
    await tester.pumpAndSettle();

    expect(find.text('Ngừng hoạt động chi nhánh?'), findsOneWidget);
    expect(api.inactivateCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Ngừng hoạt động'));
    await tester.pumpAndSettle();

    expect(api.inactivateCalls, 1);
    expect(find.text('Quản lý chi nhánh'), findsOneWidget);
  });

  testWidgets('validates and creates a branch', (tester) async {
    final api = _FakeBranchApi();
    await tester.pumpWidget(
      MaterialApp(home: AdminBranchListPage(branchApi: api)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm chi nhánh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo chi nhánh'));
    await tester.pump();
    expect(
      find.text('Vui lòng nhập tên và địa chỉ chi nhánh.'),
      findsOneWidget,
    );
    expect(api.createCalls, 0);

    await tester.enterText(
      find.widgetWithText(TextField, 'Tên chi nhánh *'),
      'Chi nhánh mới',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Địa chỉ *'),
      'Quận 3',
    );
    await tester.tap(find.text('Tạo chi nhánh'));
    await tester.pumpAndSettle();

    expect(api.createCalls, 1);
    expect(find.text('Quản lý chi nhánh'), findsOneWidget);
  });
}

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
