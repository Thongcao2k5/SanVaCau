import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  @override
  Future<List<Court>> getCourts(String branchId) async => courts;

  @override
  Future<Court> createCourt({
    required String branchId,
    required String name,
    String? description,
  }) async {
    createCalls++;
    return Court(
      id: '11',
      branchId: branchId,
      name: name,
      description: description,
      status: 'ACTIVE',
    );
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

void main() {
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
}
