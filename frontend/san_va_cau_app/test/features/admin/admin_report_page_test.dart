import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/admin/data/admin_report_api.dart';
import 'package:san_va_cau_app/features/admin/models/admin_report.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_report_page.dart';

class _MockReportApi extends AdminReportApi {
  _MockReportApi({
    this.overviewResult,
    this.productsResult,
    this.courtsResult,
    this.error,
  });

  final AdminReportOverview? overviewResult;
  final List<AdminReportTopProduct>? productsResult;
  final List<AdminReportTopCourt>? courtsResult;
  final dynamic error;

  int callCount = 0;
  int productCallCount = 0;
  int courtCallCount = 0;
  String? lastFrom;
  String? lastTo;

  @override
  Future<AdminReportOverview> getOverview({String? from, String? to}) async {
    callCount++;
    lastFrom = from;
    lastTo = to;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (error != null) throw error as Object;
    return overviewResult ??
        const AdminReportOverview(
          totalOrders: 0,
          totalOrderRevenue: 0,
          totalBookings: 0,
          totalBookingRevenue: 0,
          totalPayments: 0,
          totalPaidAmount: 0,
          totalCustomers: 0,
          totalSupportTickets: 0,
          openSupportTickets: 0,
          resolvedSupportTickets: 0,
        );
  }

  @override
  Future<List<AdminReportTopProduct>> getTopProducts({
    String? from,
    String? to,
    int limit = 5,
  }) async {
    productCallCount++;
    if (error != null) throw error as Object;
    return productsResult ?? [];
  }

  @override
  Future<List<AdminReportTopCourt>> getTopCourts({
    String? from,
    String? to,
    int limit = 5,
  }) async {
    courtCallCount++;
    if (error != null) throw error as Object;
    return courtsResult ?? [];
  }
}

Widget _app({required String role, String? branchId, AdminReportApi? api}) {
  return MaterialApp(
    home: AdminReportPage(role: role, branchId: branchId, api: api),
  );
}

void main() {
  testWidgets('denies CUSTOMER and unknown roles without API calls', (
    tester,
  ) async {
    final api = _MockReportApi();

    await tester.pumpWidget(_app(role: 'CUSTOMER', api: api));
    await tester.pumpAndSettle();

    expect(find.text('Bạn không có quyền truy cập'), findsOneWidget);
    expect(api.callCount, 0);
    expect(api.productCallCount, 0);
    expect(api.courtCallCount, 0);

    await tester.pumpWidget(_app(role: 'UNKNOWN', api: api));
    await tester.pumpAndSettle();

    expect(find.text('Bạn không có quyền truy cập'), findsOneWidget);
    expect(api.callCount, 0);
    expect(api.productCallCount, 0);
    expect(api.courtCallCount, 0);
  });

  testWidgets('allows ADMIN, BRANCH_MANAGER, STAFF and shows scope labels', (
    tester,
  ) async {
    final api = _MockReportApi();

    await tester.pumpWidget(_app(role: 'ADMIN', api: api));
    await tester.pumpAndSettle();
    expect(find.text('Toàn hệ thống'), findsOneWidget);

    await tester.pumpWidget(
      _app(role: 'BRANCH_MANAGER', branchId: '1', api: api),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chi nhánh #1'), findsOneWidget);

    await tester.pumpWidget(_app(role: 'STAFF', branchId: '2', api: api));
    await tester.pumpAndSettle();
    expect(find.text('Chi nhánh #2'), findsOneWidget);
  });

  testWidgets('shows loading, success and empty states', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final api = _MockReportApi(
      overviewResult: const AdminReportOverview(
        totalOrders: 10,
        totalOrderRevenue: 100000,
        totalBookings: 0,
        totalBookingRevenue: 0,
        totalPayments: 0,
        totalPaidAmount: 0,
        totalCustomers: 0,
        totalSupportTickets: 0,
        openSupportTickets: 0,
        resolvedSupportTickets: 0,
      ),
      productsResult: [],
      courtsResult: [],
    );

    await tester.pumpWidget(_app(role: 'ADMIN', api: api));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('10'), findsOneWidget); // totalOrders
    expect(find.text('100.000đ'), findsOneWidget); // totalOrderRevenue
    expect(find.text('Không có dữ liệu sản phẩm'), findsOneWidget);
    expect(find.text('Không có dữ liệu sân'), findsOneWidget);
  });

  testWidgets('shows error state and handles retry, displays clean message', (
    tester,
  ) async {
    const error = ApiException(statusCode: 400, message: 'Clean error message');

    final api = _MockReportApi(error: error);
    await tester.pumpWidget(_app(role: 'ADMIN', api: api));
    await tester.pumpAndSettle();

    expect(find.text('Clean error message'), findsOneWidget);
    expect(find.text('ApiException'), findsNothing);

    // Retry but still fails
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Clean error message'), findsOneWidget);
  });

  testWidgets('date range is applied and can be cleared', (tester) async {
    final api = _MockReportApi();
    final now = DateTime.now();
    final yearMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    await tester.pumpWidget(_app(role: 'ADMIN', api: api));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').first);
    await tester.pump();
    await tester.tap(find.text('11').first);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(api.lastFrom, '$yearMonth-10');
    expect(api.lastTo, '$yearMonth-11');

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(api.lastFrom, isNull);
    expect(api.lastTo, isNull);
  });

  testWidgets('empty report supports pull-to-refresh', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final api = _MockReportApi();

    await tester.pumpWidget(_app(role: 'ADMIN', api: api));
    await tester.pumpAndSettle();

    final initialCalls = api.callCount;

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(api.callCount, initialCalls + 1);
  });

  testWidgets('reload is locked while a request is running', (tester) async {
    final api = _MockReportApi();

    await tester.pumpWidget(_app(role: 'ADMIN', api: api));
    expect(api.callCount, 1);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(api.callCount, 1);
  });

  testWidgets('has no overflow at 360 logical pixels', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(_app(role: 'ADMIN', api: _MockReportApi()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
