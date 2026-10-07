import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/admin/data/admin_dashboard_api.dart';
import 'package:san_va_cau_app/features/admin/models/admin_dashboard.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_dashboard_page.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_inventory_list_page.dart';

class _FakeDashboardApi extends AdminDashboardApi {
  _FakeDashboardApi(this.fetchResult);
  final Future<AdminDashboard> Function() fetchResult;

  @override
  Future<AdminDashboard> getSummary({String? date}) {
    return fetchResult();
  }
}

Widget _app(AdminDashboardApi api) {
  return MaterialApp(home: AdminDashboardPage(dashboardApi: api));
}

void main() {
  testWidgets('renders loading state initially', (tester) async {
    final api = _FakeDashboardApi(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      throw Exception(); // Won't reach here
    });

    await tester.pumpWidget(_app(api));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('renders success state with empty activity', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final api = _FakeDashboardApi(() async {
      return const AdminDashboard(
        role: 'ADMIN',
        branchId: null,
        date: '2026-10-06',
        bookings: AdminBookingSummary(
          total: 0,
          booked: 0,
          checkedIn: 0,
          completed: 0,
          cancelled: 0,
        ),
        orders: AdminOrderSummary(
          total: 0,
          pending: 0,
          readyForPickup: 0,
          completed: 0,
          cancelled: 0,
          revenueCompleted: 0,
        ),
        inventory: AdminInventorySummary(lowStockCount: 0, lowStockItems: []),
        courts: AdminCourtSummary(active: 0, maintenance: 0, inactive: 0),
        latestBookings: [],
        latestOrders: [],
      );
    });

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Toàn hệ thống • 2026-10-06'), findsOneWidget);
    expect(find.text('Chưa có hoạt động gần đây'), findsOneWidget);
    expect(find.text('Quản lý nhân viên'), findsOneWidget);
    expect(find.text('Quản lý nội dung'), findsOneWidget);
    expect(find.text('Báo cáo tổng hợp'), findsOneWidget);

    final inventoryCard = find
        .ancestor(of: find.text('Sắp hết hàng'), matching: find.byType(InkWell))
        .first;
    tester.widget<InkWell>(inventoryCard).onTap!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AdminInventoryListPage), findsOneWidget);
  });

  testWidgets('renders success state with activities', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final api = _FakeDashboardApi(() async {
      return const AdminDashboard(
        role: 'STAFF',
        branchId: '1',
        date: '2026-10-06',
        bookings: AdminBookingSummary(
          total: 10,
          booked: 2,
          checkedIn: 1,
          completed: 5,
          cancelled: 2,
        ),
        orders: AdminOrderSummary(
          total: 15,
          pending: 3,
          readyForPickup: 2,
          completed: 9,
          cancelled: 1,
          revenueCompleted: 150000,
        ),
        inventory: AdminInventorySummary(
          lowStockCount: 1,
          lowStockItems: [
            AdminLowStockItem(
              id: '1',
              branchName: 'Branch 1',
              productName: 'Racket',
              variantName: 'Red',
              sku: 'R-R',
              quantity: 1,
            ),
          ],
        ),
        courts: AdminCourtSummary(active: 5, maintenance: 0, inactive: 0),
        latestBookings: [
          AdminRecentBooking(
            id: '99',
            date: '2026-10-06',
            status: 'BOOKED',
            totalAmount: 50000,
            courtName: 'Court 1',
            branchName: 'Branch 1',
            customerName: 'John Doe',
          ),
        ],
        latestOrders: [
          AdminRecentOrder(
            id: '88',
            status: 'COMPLETED',
            totalAmount: 100000,
            createdAt: null,
            branchName: 'Branch 1',
            customerName: 'Jane Doe',
          ),
        ],
      );
    });

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Chi nhánh #1 • 2026-10-06'), findsOneWidget);
    expect(find.textContaining('Lịch #99'), findsOneWidget);
    expect(find.textContaining('Đơn #88'), findsOneWidget);
    expect(find.textContaining('Racket'), findsOneWidget);
  });

  testWidgets('renders error state and handles retry', (tester) async {
    var fail = true;
    final api = _FakeDashboardApi(() async {
      if (fail) {
        throw const ApiException(statusCode: 500, message: 'Server error');
      }
      return const AdminDashboard(
        role: 'ADMIN',
        branchId: null,
        date: '2026-10-06',
        bookings: AdminBookingSummary(
          total: 0,
          booked: 0,
          checkedIn: 0,
          completed: 0,
          cancelled: 0,
        ),
        orders: AdminOrderSummary(
          total: 0,
          pending: 0,
          readyForPickup: 0,
          completed: 0,
          cancelled: 0,
          revenueCompleted: 0,
        ),
        inventory: AdminInventorySummary(lowStockCount: 0, lowStockItems: []),
        courts: AdminCourtSummary(active: 0, maintenance: 0, inactive: 0),
        latestBookings: [],
        latestOrders: [],
      );
    });

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải dữ liệu quản trị'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Toàn hệ thống • 2026-10-06'), findsOneWidget);
  });

  testWidgets('Dashboard hides ADMIN entries for STAFF and BRANCH_MANAGER', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final role in ['STAFF', 'BRANCH_MANAGER']) {
      final api = _FakeDashboardApi(() async {
        return AdminDashboard(
          role: role,
          branchId: '1',
          date: '2026-10-06',
          bookings: const AdminBookingSummary(
            total: 0,
            booked: 0,
            checkedIn: 0,
            completed: 0,
            cancelled: 0,
          ),
          orders: const AdminOrderSummary(
            total: 0,
            pending: 0,
            readyForPickup: 0,
            completed: 0,
            cancelled: 0,
            revenueCompleted: 0,
          ),
          inventory: const AdminInventorySummary(
            lowStockCount: 0,
            lowStockItems: [],
          ),
          courts: const AdminCourtSummary(
            active: 0,
            maintenance: 0,
            inactive: 0,
          ),
          latestBookings: const [],
          latestOrders: const [],
        );
      });

      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();

      expect(find.text('Quản lý nhân viên'), findsNothing, reason: role);
      expect(find.text('Quản lý nội dung'), findsNothing, reason: role);
      expect(find.text('Báo cáo tổng hợp'), findsOneWidget, reason: role);
    }
  });
}
