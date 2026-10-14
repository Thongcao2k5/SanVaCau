import 'dart:async';

import 'package:flutter/material.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/theme/app_theme.dart';

import 'admin_test_accessibility.dart';

import 'package:san_va_cau_app/features/admin/data/admin_court_api.dart';
import 'package:san_va_cau_app/features/admin/models/admin_court.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_court_list_page.dart';
import 'package:san_va_cau_app/features/booking/models/court.dart';
import 'package:san_va_cau_app/features/branches/models/branch.dart';

const _branch = Branch(
  id: '1',
  name: 'Chi nhánh Trung tâm',
  address: 'Quận 1',
  openingTime: '06:00',
  closingTime: '22:00',
  status: 'ACTIVE',
);

const _court = Court(
  id: '10',
  branchId: '1',
  name: 'Sân A',
  description: 'Sân thảm xanh',
  status: 'ACTIVE',
);

class _FakeCourtApi extends AdminCourtApi {
  List<Court> courts = const [_court];
  int createCalls = 0;
  int updateCalls = 0;
  int listCalls = 0;
  String? inactivatedId;
  Map<String, Object?>? saved;
  Completer<Court>? pending;
  bool failSave = false;

  @override
  Future<List<Court>> getCourts(String branchId) async {
    listCalls++;
    return courts;
  }

  @override
  Future<Court> createCourt({
    required String branchId,
    required String name,
    String? description,
  }) async {
    createCalls++;
    saved = {'branchId': branchId, 'name': name, 'description': description};
    if (failSave) {
      throw const ApiException(
        statusCode: 500,
        message: 'Không thể lưu thử nghiệm',
      );
    }
    if (pending != null) return pending!.future;
    return Court(
      id: '11',
      branchId: branchId,
      name: name,
      description: description,
      status: 'ACTIVE',
    );
  }

  @override
  Future<Court> updateCourt({
    required String id,
    required String name,
    String? description,
    String? status,
  }) async {
    updateCalls++;
    saved = {
      'id': id,
      'name': name,
      'description': description,
      'status': status,
    };
    if (failSave) {
      throw const ApiException(
        statusCode: 500,
        message: 'Không thể lưu thử nghiệm',
      );
    }
    if (pending != null) return pending!.future;
    return _court;
  }

  @override
  Future<void> inactivateCourt(String id) async {
    inactivatedId = id;
  }

  @override
  Future<List<AdminTimeSlot>> getTimeSlots() async => const [
    AdminTimeSlot(
      id: '101',
      startTime: '06:00:00',
      endTime: '07:00:00',
      sortOrder: 1,
      isActive: true,
    ),
  ];

  @override
  Future<List<CourtPrice>> getCourtPrices(String courtId) async => const [
    CourtPrice(
      id: '201',
      timeSlotId: '101',
      price: 120000,
      startTime: '06:00:00',
      endTime: '07:00:00',
      isActive: true,
    ),
  ];
}

class _FakeSlotApi extends _FakeCourtApi {
  int slotLoads = 0;
  int slotCreates = 0;
  int slotUpdates = 0;
  Map<String, Object?>? slotBody;
  Completer<AdminTimeSlot>? slotPending;
  bool failSlotSave = false;

  @override
  Future<List<AdminTimeSlot>> getTimeSlots() async {
    slotLoads++;
    return super.getTimeSlots();
  }

  @override
  Future<AdminTimeSlot> createTimeSlot({
    required String startTime,
    required String endTime,
    required int sortOrder,
  }) async {
    slotCreates++;
    slotBody = {
      'startTime': startTime,
      'endTime': endTime,
      'sortOrder': sortOrder,
    };
    return _slotResult();
  }

  @override
  Future<AdminTimeSlot> updateTimeSlot({
    required String id,
    required String startTime,
    required String endTime,
    required int sortOrder,
    bool? isActive,
  }) async {
    slotUpdates++;
    slotBody = {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
    return _slotResult();
  }

  Future<AdminTimeSlot> _slotResult() async {
    if (failSlotSave) {
      throw const ApiException(statusCode: 409, message: 'Khung giờ bị trùng');
    }
    if (slotPending != null) return slotPending!.future;
    return const AdminTimeSlot(
      id: '101',
      startTime: '06:00:00',
      endTime: '07:00:00',
      sortOrder: 1,
      isActive: true,
    );
  }
}

class _FakePriceApi extends _FakeCourtApi {
  bool emptySlots = false;
  bool failLoad = false;
  bool failPriceSave = false;
  bool unexpectedFailure = false;
  int priceCalls = 0;
  String? savedCourtId;
  Map<String, double>? savedPrices;
  Completer<List<CourtPrice>>? pendingPrices;
  Completer<List<CourtPrice>>? pendingLoad;
  List<CourtPrice> prices = const [
    CourtPrice(
      id: '2',
      timeSlotId: '102',
      price: 80000,
      startTime: '07:00',
      endTime: '08:00',
      isActive: true,
    ),
    CourtPrice(
      id: '1',
      timeSlotId: '101',
      price: 120000.5,
      startTime: '06:00',
      endTime: '07:00',
      isActive: true,
    ),
  ];

  @override
  Future<List<AdminTimeSlot>> getTimeSlots() async => emptySlots
      ? []
      : const [
          AdminTimeSlot(
            id: '101',
            startTime: '06:00',
            endTime: '07:00',
            sortOrder: 1,
            isActive: true,
          ),
          AdminTimeSlot(
            id: '102',
            startTime: '07:00',
            endTime: '08:00',
            sortOrder: 2,
            isActive: true,
          ),
        ];

  @override
  Future<List<CourtPrice>> getCourtPrices(String courtId) async {
    if (failLoad) {
      throw const ApiException(statusCode: 500, message: 'Lỗi tải bảng giá');
    }
    if (pendingLoad != null) return pendingLoad!.future;
    return prices;
  }

  @override
  Future<List<CourtPrice>> updateCourtPrices({
    required String courtId,
    required Map<String, double> prices,
  }) async {
    priceCalls++;
    savedCourtId = courtId;
    savedPrices = Map.of(prices);
    if (unexpectedFailure) throw StateError('unexpected');
    if (failPriceSave) {
      throw const ApiException(statusCode: 500, message: 'Lỗi lưu bảng giá');
    }
    if (pendingPrices != null) return pendingPrices!.future;
    return this.prices;
  }
}

void main() {
  for (final size in [
    const Size(320, 800),
    const Size(375, 800),
    const Size(800, 375),
  ]) {
    testWidgets('court list and prices at $size with large text', (
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
          home: AdminCourtListPage(branch: _branch, courtApi: _FakeCourtApi()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectAdminAccessibility(tester);
      await tester.tap(find.text(_court.name));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectAdminAccessibility(tester);
      await tester.drag(find.byType(ListView).last, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectAdminAccessibility(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm sân'));
      await tester.pumpAndSettle();
      await expectAdminAccessibility(tester);
      await _scrollToSave(tester);
      expect(tester.takeException(), isNull);
      await expectAdminAccessibility(tester);
    });
  }
  testWidgets('lists courts and opens their price editor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminCourtListPage(branch: _branch, courtApi: _FakeCourtApi()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sân A'), findsOneWidget);
    expect(find.text('Sân thảm xanh'), findsOneWidget);
    await tester.tap(find.text('Sân A'));
    await tester.pumpAndSettle();

    expect(find.text('Giá theo khung giờ'), findsOneWidget);
    expect(find.text('06:00 – 07:00'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '06:00 – 07:00'), findsOneWidget);
  });

  testWidgets('validates court name before creating', (tester) async {
    final api = _FakeCourtApi()..courts = const [];
    await tester.pumpWidget(
      MaterialApp(
        home: AdminCourtListPage(branch: _branch, courtApi: api),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm sân đầu tiên'));
    await tester.pumpAndSettle();
    await _scrollToSave(tester);
    await tester.tap(find.text('Lưu sân'));
    await tester.pump();

    expect(find.text('Nhập tên sân'), findsOneWidget);
    expect(api.createCalls, 0);
  });

  testWidgets('time-slot page renders active slots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AdminTimeSlotPage(courtApi: _FakeCourtApi())),
    );
    await tester.pumpAndSettle();

    expect(find.text('06:00 – 07:00'), findsOneWidget);
    expect(find.text('Thứ tự 1'), findsOneWidget);
  });

  for (final editing in [false, true]) {
    testWidgets(
      '${editing ? 'edit' : 'create'} court preserves payload, locks save and reloads',
      (tester) async {
        final api = _FakeCourtApi()..pending = Completer<Court>();
        await tester.pumpWidget(
          MaterialApp(
            home: AdminCourtListPage(branch: _branch, courtApi: api),
          ),
        );
        await tester.pumpAndSettle();
        if (editing) {
          await tester.tap(find.byTooltip('Thao tác sân'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Sửa sân'));
        } else {
          await tester.tap(find.text('Thêm sân'));
        }
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('court-name')))
              .controller!
              .text,
          editing ? 'Sân A' : '',
        );
        await tester.enterText(find.byKey(const Key('court-name')), ' Sân B ');
        await tester.enterText(find.byKey(const Key('court-description')), ' ');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await _scrollToSave(tester);
        await tester.tap(find.byKey(const Key('court-save')));
        await tester.tap(find.byKey(const Key('court-save')));
        await tester.pump();
        expect(api.createCalls + api.updateCalls, 1);
        expect(
          api.saved,
          editing
              ? {
                  'id': '10',
                  'name': 'Sân B',
                  'description': null,
                  'status': null,
                }
              : {'branchId': '1', 'name': 'Sân B', 'description': null},
        );
        for (final field in tester.widgetList<TextFormField>(
          find.byType(TextFormField),
        )) {
          expect(field.enabled, false);
        }
        expect(find.text('Đang lưu...'), findsOneWidget);
        api.pending!.complete(_court);
        await tester.pumpAndSettle();
        expect(api.listCalls, 2);
        expect(find.text('Sân A'), findsOneWidget);
      },
    );
  }

  testWidgets('court hide requires confirmation then reloads', (tester) async {
    final api = _FakeCourtApi();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminCourtListPage(branch: _branch, courtApi: api),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đang hoạt động'), findsOneWidget);
    expect(find.text('Xem bảng giá'), findsOneWidget);
    for (final confirm in [false, true]) {
      await tester.tap(find.byTooltip('Thao tác sân'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ngừng hoạt động'));
      await tester.pumpAndSettle();
      expect(api.inactivatedId, isNull);
      await tester.tap(find.text(confirm ? 'Ngừng hoạt động' : 'Bỏ qua'));
      await tester.pumpAndSettle();
    }
    expect(api.inactivatedId, '10');
    expect(api.listCalls, 2);
  });

  testWidgets('court save error preserves input and enables retry', (
    tester,
  ) async {
    final api = _FakeCourtApi()..failSave = true;
    await tester.pumpWidget(
      MaterialApp(
        home: AdminCourtListPage(branch: _branch, courtApi: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm sân'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('court-name')), 'Sân mới');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _scrollToSave(tester);
    await tester.tap(find.byKey(const Key('court-save')));
    await tester.pumpAndSettle();
    expect(find.text('Không thể lưu thử nghiệm'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('court-name')))
          .controller!
          .text,
      'Sân mới',
    );
    api.failSave = false;
    await _scrollToSave(tester);
    await tester.tap(find.byKey(const Key('court-save')));
    await tester.pumpAndSettle();
    expect(api.createCalls, 2);
    expect(api.listCalls, 2);
  });

  for (final editing in [false, true]) {
    testWidgets(
      '${editing ? 'edit' : 'create'} slot payload and pending guard',
      (tester) async {
        final api = _FakeSlotApi()..slotPending = Completer<AdminTimeSlot>();
        await tester.pumpWidget(
          MaterialApp(home: AdminTimeSlotPage(courtApi: api)),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(editing ? '06:00 – 07:00' : 'Thêm khung giờ'),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('slot-start')))
              .controller!
              .text,
          editing ? '06:00' : '',
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('slot-order')))
              .controller!
              .text,
          editing ? '1' : '0',
        );
        await _enterSlot(tester, 'slot-start', ' 08:00 ');
        await _enterSlot(tester, 'slot-end', '09:00');
        await _tapSlotSave(tester);
        await tester.tap(find.byKey(const Key('slot-save')));
        await tester.pump();
        expect(api.slotCreates + api.slotUpdates, 1);
        expect(
          api.slotBody,
          editing
              ? {
                  'id': '101',
                  'startTime': '08:00',
                  'endTime': '09:00',
                  'sortOrder': 1,
                  'isActive': null,
                }
              : {'startTime': '08:00', 'endTime': '09:00', 'sortOrder': 0},
        );
        for (final field in tester.widgetList<TextField>(
          find.byType(TextField),
        )) {
          expect(field.enabled, false);
        }
        expect(find.text('Đang lưu...'), findsOneWidget);
        api.slotPending!.complete(
          const AdminTimeSlot(
            id: '101',
            startTime: '08:00',
            endTime: '09:00',
            sortOrder: 0,
            isActive: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(api.slotLoads, 2);
      },
    );
  }

  testWidgets(
    'slot validates time and order before API; failed save keeps inputs',
    (tester) async {
      final api = _FakeSlotApi();
      await tester.pumpWidget(
        MaterialApp(home: AdminTimeSlotPage(courtApi: api)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thêm khung giờ'));
      await tester.pumpAndSettle();
      for (final times in [
        ['25:00', '09:00'],
        ['09:00', '09:00'],
        ['10:00', '09:00'],
      ]) {
        await _enterSlot(tester, 'slot-start', times[0]);
        await _enterSlot(tester, 'slot-end', times[1]);
        await _tapSlotSave(tester);
        await tester.pumpAndSettle();
        expect(find.text('Giờ bắt đầu/kết thúc không hợp lệ.'), findsOneWidget);
        expect(api.slotCreates, 0);
      }
      await _enterSlot(tester, 'slot-start', '08:00');
      for (final order in ['-1', '1.5']) {
        await _enterSlot(tester, 'slot-order', order);
        await _tapSlotSave(tester);
        await tester.pumpAndSettle();
        expect(find.text('Thứ tự phải là số nguyên không âm.'), findsOneWidget);
        expect(api.slotCreates, 0);
      }
      await _enterSlot(tester, 'slot-order', '2');
      api.failSlotSave = true;
      await _tapSlotSave(tester);
      await tester.pumpAndSettle();
      expect(find.text('Khung giờ bị trùng'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('slot-start')))
            .controller!
            .text,
        '08:00',
      );
      api.failSlotSave = false;
      await _tapSlotSave(tester);
      await tester.pumpAndSettle();
      expect(api.slotCreates, 2);
      expect(api.slotLoads, 2);
    },
  );

  testWidgets('slot disable cancel and confirm preserve full payload', (
    tester,
  ) async {
    final api = _FakeSlotApi();
    await tester.pumpWidget(
      MaterialApp(home: AdminTimeSlotPage(courtApi: api)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đang hoạt động'), findsOneWidget);
    for (final confirm in [false, true]) {
      await tester.tap(find.byTooltip('Thao tác khung giờ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tắt'));
      await tester.pumpAndSettle();
      expect(api.slotUpdates, 0);
      await tester.tap(find.text(confirm ? 'Tắt khung giờ' : 'Bỏ qua'));
      await tester.pumpAndSettle();
    }
    expect(api.slotBody, {
      'id': '101',
      'startTime': '06:00:00',
      'endTime': '07:00:00',
      'sortOrder': 1,
      'isActive': false,
    });
    expect(api.slotLoads, 2);
  });

  for (final size in [
    const Size(320, 800),
    const Size(375, 800),
    const Size(800, 375),
  ]) {
    testWidgets(
      'slot list/dialog accessible at $size with keyboard and large text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.5),
                viewInsets: const EdgeInsets.only(bottom: 160),
              ),
              child: child!,
            ),
            home: AdminTimeSlotPage(courtApi: _FakeSlotApi()),
          ),
        );
        await tester.pumpAndSettle();
        await expectAdminAccessibility(tester);
        await tester.tap(find.text('Thêm khung giờ'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('slot-save')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getBottomRight(find.byKey(const Key('slot-save'))).dy,
          lessThanOrEqualTo(size.height - 160),
        );
        await expectAdminAccessibility(tester);
      },
    );
  }

  testWidgets('price map preserves decimals and locks pending save', (
    tester,
  ) async {
    final api = _FakePriceApi()..pendingPrices = Completer<List<CourtPrice>>();
    await _openPrices(tester, api);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('court-price-101')))
          .controller!
          .text,
      '120000.5',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('court-price-102')))
          .controller!
          .text,
      '80000',
    );
    await _tapPriceSave(tester);
    await tester.tap(find.byKey(const Key('court-price-save')));
    await tester.pump();
    expect(api.priceCalls, 1);
    expect(api.savedCourtId, '10');
    expect(api.savedPrices, {'101': 120000.5, '102': 80000.0});
    for (final input in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(input.enabled, false);
    }
    api.pendingPrices!.complete(api.prices);
    await tester.pumpAndSettle();
    expect(find.text('Đã cập nhật bảng giá'), findsOneWidget);
  });

  testWidgets('missing and invalid prices never reach API', (tester) async {
    final api = _FakePriceApi()..prices = [];
    await _openPrices(tester, api);
    await _tapPriceSave(tester);
    await tester.pumpAndSettle();
    expect(api.priceCalls, 0);
    await _enterPrice(tester, '102', '100');
    for (final invalid in ['', '0', '-1', 'bad', 'NaN', 'Infinity']) {
      await _enterPrice(tester, '101', invalid);
      await _tapPriceSave(tester);
      await tester.pumpAndSettle();
      expect(api.priceCalls, 0);
      expect(
        find.text('Nhập giá hợp lệ cho tất cả khung giờ.'),
        findsOneWidget,
      );
    }
  });

  testWidgets('price load retry and both save errors preserve input', (
    tester,
  ) async {
    final api = _FakePriceApi()..failLoad = true;
    await _openPrices(tester, api);
    expect(find.text('Lỗi tải bảng giá'), findsOneWidget);
    api.failLoad = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    await _enterPrice(tester, '101', '123.75');
    for (final unexpected in [false, true]) {
      api.failPriceSave = !unexpected;
      api.unexpectedFailure = unexpected;
      await _tapPriceSave(tester);
      await tester.pumpAndSettle();
      expect(
        find.text(
          unexpected
              ? 'Không thể lưu bảng giá. Vui lòng thử lại.'
              : 'Lỗi lưu bảng giá',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('court-price-101')),
            )
            .controller!
            .text,
        '123.75',
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('court-price-save')))
            .onPressed,
        isNotNull,
      );
    }
    api.unexpectedFailure = false;
    api.failPriceSave = false;
    await _tapPriceSave(tester);
    await tester.pumpAndSettle();
    expect(api.savedPrices!['101'], 123.75);
    expect(api.priceCalls, 3);
  });

  testWidgets('price empty slots has guidance and no save action', (
    tester,
  ) async {
    await _openPrices(tester, _FakePriceApi()..emptySlots = true);
    expect(
      find.text('Hãy tạo khung giờ trước khi cập nhật giá.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('court-price-save')), findsNothing);
  });

  testWidgets('leaving while prices load causes no late state errors', (
    tester,
  ) async {
    final api = _FakePriceApi()..pendingLoad = Completer<List<CourtPrice>>();
    await tester.pumpWidget(
      MaterialApp(
        home: AdminCourtListPage(branch: _branch, courtApi: api),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sân A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pageBack();
    await tester.pumpAndSettle();
    api.pendingLoad!.complete(api.prices);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('price save is keyboard safe at 320dp with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
            viewInsets: const EdgeInsets.only(bottom: 250),
          ),
          child: child!,
        ),
        home: AdminCourtListPage(branch: _branch, courtApi: _FakePriceApi()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sân A'));
    await tester.pumpAndSettle();
    await _showPriceSave(tester);
    expect(
      tester.getBottomRight(find.byKey(const Key('court-price-save'))).dy,
      lessThanOrEqualTo(550),
    );
    expect(tester.takeException(), isNull);
    await expectAdminAccessibility(tester);
  });

  testWidgets('court submit stays above keyboard at 320dp and large text', (
    tester,
  ) async {
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
        home: AdminCourtListPage(branch: _branch, courtApi: _FakeCourtApi()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm sân'));
    await tester.pumpAndSettle();
    await _scrollToSave(tester);
    expect(
      tester.getBottomRight(find.byKey(const Key('court-save'))).dy,
      lessThanOrEqualTo(550),
    );
    expect(tester.takeException(), isNull);
    await expectAdminAccessibility(tester);
  });
}

Future<void> _scrollToSave(WidgetTester tester) async {
  final save = find.byKey(const Key('court-save'));
  await tester.scrollUntilVisible(
    save,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
}

Future<void> _enterSlot(WidgetTester tester, String key, String text) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
}

Future<void> _openPrices(WidgetTester tester, _FakePriceApi api) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AdminCourtListPage(branch: _branch, courtApi: api),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sân A'));
  await tester.pumpAndSettle();
}

Future<void> _enterPrice(WidgetTester tester, String id, String value) async {
  final field = find.byKey(ValueKey('court-price-$id'));
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, value);
}

Future<void> _showPriceSave(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final button = find.byKey(const Key('court-price-save'));
  await tester.scrollUntilVisible(
    button,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
}

Future<void> _tapPriceSave(WidgetTester tester) async {
  await _showPriceSave(tester);
  await tester.tap(find.byKey(const Key('court-price-save')));
}

Future<void> _tapSlotSave(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final save = find.byKey(const Key('slot-save'));
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
}
