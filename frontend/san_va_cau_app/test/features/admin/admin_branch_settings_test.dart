import 'dart:async';

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
  List<Branch> branches = const [_branch];
  bool? savedFeatured;
  int? savedSortOrder;
  var inactivateCalls = 0;
  var createCalls = 0;
  var updateCalls = 0;
  var listCalls = 0;
  Map<String, Object?>? savedBody;
  Completer<Branch>? pending;

  @override
  Future<List<Branch>> getBranches() async {
    listCalls++;
    return branches;
  }

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
    updateCalls++;
    savedBody = {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'description': description,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'imageUrl': imageUrl,
      'isFeatured': isFeatured,
      'sortOrder': sortOrder,
    };
    if (pending != null) return pending!.future;
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
    savedBody = {
      'name': name,
      'address': address,
      'phone': phone,
      'description': description,
      'openingTime': openingTime,
      'closingTime': closingTime,
    };
    if (pending != null) return pending!.future;
    return _branch;
  }
}

void main() {
  for (final value in [
    '06:00:30',
    '6:00:00',
    '25:00:00',
    '06:99:00',
    '06:00:00junk',
  ]) {
    testWidgets('settings does not coerce invalid server time $value', (
      tester,
    ) async {
      _useTallView(tester);
      final api = _FakeBranchApi()
        ..branches = [
          Branch(
            id: '1',
            name: _branch.name,
            address: _branch.address,
            openingTime: value,
            closingTime: '22:00',
            status: 'ACTIVE',
            isFeatured: false,
            sortOrder: 0,
          ),
        ];
      await tester.pumpWidget(
        MaterialApp(home: AdminBranchListPage(branchApi: api)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(_branch.name));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('branch-opening-time')))
            .controller!
            .text,
        value,
      );
      await _scrollTo(tester, find.byKey(const Key('branch-settings-save')));
      await tester.tap(find.byKey(const Key('branch-settings-save')));
      await tester.pumpAndSettle();
      expect(
        find.text('Giờ hoạt động phải có định dạng HH:mm.'),
        findsOneWidget,
      );
      expect(api.updateCalls, 0);
    });
  }

  testWidgets('settings normalizes server zero seconds without blocking save', (
    tester,
  ) async {
    _useTallView(tester);
    final api = _FakeBranchApi()
      ..branches = const [
        Branch(
          id: '1',
          name: 'Chi nhánh Trung tâm',
          address: 'Quận 1',
          openingTime: '06:00:00',
          closingTime: '22:00:00',
          status: 'ACTIVE',
          isFeatured: false,
          sortOrder: 0,
        ),
      ];
    await tester.pumpWidget(
      MaterialApp(home: AdminBranchListPage(branchApi: api)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_branch.name));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('branch-opening-time')))
          .controller!
          .text,
      '06:00',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('branch-closing-time')))
          .controller!
          .text,
      '22:00',
    );
    await _scrollTo(tester, find.byKey(const Key('branch-settings-save')));
    await tester.tap(find.byKey(const Key('branch-settings-save')));
    await tester.pumpAndSettle();
    expect(api.updateCalls, 1);
    expect(api.savedBody!['openingTime'], '06:00');
    expect(api.savedBody!['closingTime'], '22:00');
    expect(api.listCalls, 2);
  });

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
      await _scrollTo(tester, find.text(_branch.name));
      await tester.tap(find.text(_branch.name));
      await tester.pumpAndSettle();
      expect(find.text('Thông tin chi nhánh'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectAdminAccessibility(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm chi nhánh'));
      await tester.pumpAndSettle();
      await expectAdminAccessibility(tester);
      await _scrollTo(tester, find.byKey(const Key('branch-create-save')));
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
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
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
    expect(api.savedBody, {
      'id': '1',
      'name': _branch.name,
      'address': _branch.address,
      'phone': '',
      'description': '',
      'openingTime': '06:00',
      'closingTime': '22:00',
      'imageUrl': null,
      'isFeatured': true,
      'sortOrder': 3,
    });
    expect(api.listCalls, 2);
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
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Ngừng hoạt động chi nhánh'));
    await tester.pumpAndSettle();

    expect(find.text('Ngừng hoạt động chi nhánh?'), findsOneWidget);
    expect(api.inactivateCalls, 0);

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(api.inactivateCalls, 0);
    await tester.tap(find.text('Ngừng hoạt động chi nhánh'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Ngừng hoạt động'));
    await tester.pumpAndSettle();

    expect(api.inactivateCalls, 1);
    expect(api.listCalls, 2);
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
    await _scrollTo(tester, find.byKey(const Key('branch-create-save')));
    await tester.tap(find.text('Tạo chi nhánh'));
    await tester.pump();
    expect(
      find.text('Vui lòng nhập tên và địa chỉ chi nhánh.'),
      findsOneWidget,
    );
    expect(api.createCalls, 0);

    await _scrollTo(
      tester,
      find.widgetWithText(TextField, 'Tên chi nhánh *'),
      delta: -250,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Tên chi nhánh *'),
      ' Chi nhánh mới ',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Địa chỉ *'),
      ' Quận 3 ',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('branch-create-save')));
    await tester.tap(find.text('Tạo chi nhánh'));
    await tester.pumpAndSettle();

    expect(api.createCalls, 1);
    expect(api.savedBody, {
      'name': 'Chi nhánh mới',
      'address': 'Quận 3',
      'phone': '',
      'description': '',
      'openingTime': '06:00',
      'closingTime': '22:00',
    });
    expect(api.listCalls, 2);
    expect(find.text('Quản lý chi nhánh'), findsOneWidget);
  });

  for (final editing in [false, true]) {
    testWidgets(
      '${editing ? 'settings' : 'create'} preserves hours validation and locks pending save',
      (tester) async {
        _useTallView(tester);
        final api = _FakeBranchApi();
        await tester.pumpWidget(
          MaterialApp(home: AdminBranchListPage(branchApi: api)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(editing ? _branch.name : 'Thêm chi nhánh'));
        await tester.pumpAndSettle();
        if (!editing) {
          await tester.enterText(
            find.widgetWithText(TextField, 'Tên chi nhánh *'),
            'New branch',
          );
          await tester.enterText(
            find.widgetWithText(TextField, 'Địa chỉ *'),
            'New address',
          );
        } else {
          expect(
            tester
                .widget<TextField>(
                  find.widgetWithText(TextField, 'Tên chi nhánh *'),
                )
                .controller!
                .text,
            _branch.name,
          );
          expect(find.text('Chọn ảnh'), findsOneWidget);
        }
        final opening = find.byKey(const Key('branch-opening-time'));
        final submit = find.byKey(
          Key(editing ? 'branch-settings-save' : 'branch-create-save'),
        );
        await tester.enterText(opening, '25:00');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await _scrollTo(tester, submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(
          find.text('Giờ hoạt động phải có định dạng HH:mm.'),
          findsOneWidget,
        );
        expect(api.createCalls + api.updateCalls, 0);
        await _scrollTo(tester, opening, delta: -250);
        await tester.enterText(opening, '22:00');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await _scrollTo(tester, submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(
          find.text('Giờ mở cửa phải sớm hơn giờ đóng cửa.'),
          findsOneWidget,
        );
        expect(api.createCalls + api.updateCalls, 0);
        await _scrollTo(tester, opening, delta: -250);
        await tester.enterText(opening, '07:00');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        api.pending = Completer<Branch>();
        await _scrollTo(tester, submit);
        await tester.tap(submit);
        await tester.tap(submit);
        await tester.pump();
        expect(api.createCalls + api.updateCalls, 1);
        expect(api.savedBody!['openingTime'], '07:00');
        expect(tester.widget<FilledButton>(submit).onPressed, isNull);
        for (final field in tester.widgetList<TextField>(
          find.byType(TextField),
        )) {
          expect(field.enabled, false);
        }
        expect(
          find.text(editing ? 'Đang lưu...' : 'Đang tạo...'),
          findsOneWidget,
        );
        api.pending!.complete(_branch);
        await tester.pumpAndSettle();
        expect(find.text('Quản lý chi nhánh'), findsOneWidget);
        expect(api.listCalls, 2);
      },
    );

    testWidgets(
      '${editing ? 'settings' : 'create'} submit stays above keyboard at 320dp',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                viewInsets: const EdgeInsets.only(bottom: 250),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: child!,
            ),
            home: AdminBranchListPage(branchApi: _FakeBranchApi()),
          ),
        );
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.text(_branch.name));
        await tester.tap(find.text(editing ? _branch.name : 'Thêm chi nhánh'));
        await tester.pumpAndSettle();
        final submit = find.byKey(
          Key(editing ? 'branch-settings-save' : 'branch-create-save'),
        );
        await _scrollTo(tester, submit);
        expect(tester.getBottomRight(submit).dy, lessThanOrEqualTo(550));
        expect(tester.takeException(), isNull);
        await expectAdminAccessibility(tester);
      },
    );
  }
}

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Future<void> _scrollTo(
  WidgetTester tester,
  Finder finder, {
  double delta = 250,
}) async {
  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}
