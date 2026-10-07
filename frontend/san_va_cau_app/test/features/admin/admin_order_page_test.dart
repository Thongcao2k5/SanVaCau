import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/admin/pages/admin_order_list_page.dart';
import 'package:san_va_cau_app/features/orders/data/order_api.dart';
import 'package:san_va_cau_app/features/orders/models/order.dart';

class _FakeOrderApi extends OrderApi {
  _FakeOrderApi(this.fetchOrdersResult, [this.updateResult]);

  final Future<List<Order>> Function(String? status) fetchOrdersResult;
  final Future<Order> Function(String id, String status)? updateResult;

  @override
  Future<List<Order>> getAdminOrders({
    String? branchId,
    String? customerId,
    String? status,
  }) {
    return fetchOrdersResult(status);
  }

  @override
  Future<Order> getAdminOrderById(String id) async {
    return (await fetchOrdersResult(null)).firstWhere((o) => o.id == id);
  }

  @override
  Future<Order> updateAdminOrderStatus({
    required String id,
    required String status,
  }) async {
    if (updateResult != null) return updateResult!(id, status);
    throw UnimplementedError();
  }
}

Widget _app(OrderApi api) {
  return MaterialApp(home: AdminOrderListPage(orderApi: api));
}

void main() {
  testWidgets('renders loading state initially', (tester) async {
    final api = _FakeOrderApi((status) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return [];
    });

    await tester.pumpWidget(_app(api));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('renders error and retry state', (tester) async {
    var fail = true;
    final api = _FakeOrderApi((status) async {
      if (fail) {
        throw const ApiException(statusCode: 500, message: 'Lỗi server');
      }
      return [];
    });

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải danh sách đơn hàng'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Không có đơn hàng nào'), findsOneWidget);
  });

  testWidgets('renders empty state', (tester) async {
    final api = _FakeOrderApi((status) async => []);

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Không có đơn hàng nào'), findsOneWidget);
  });

  testWidgets('status filter sends the correct backend status', (tester) async {
    String? requestedStatus;
    final api = _FakeOrderApi((status) async {
      requestedStatus = status;
      return [];
    });

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(requestedStatus, null);

    await tester.tap(find.text('Chờ nhận hàng'));
    await tester.pumpAndSettle();

    expect(requestedStatus, 'READY_FOR_PICKUP');
  });

  testWidgets('tapping an order opens its detail page and shows fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final order = Order(
      id: '99',
      customerId: '1',
      branchId: '2',
      status: 'PENDING',
      totalAmount: '200000',
      createdAt: DateTime.tryParse('2026-10-06T10:00:00Z'),
      customer: const OrderCustomer(
        id: '1',
        fullName: 'John Wick',
        phone: '0987654321',
      ),
      branch: const OrderBranch(id: '2', name: 'Chi nhánh VIP', address: 'HN'),
      items: [
        const OrderItem(
          id: '1',
          productVariantId: '1',
          productName: 'Vợt cầu lông',
          variantName: 'Đen',
          unitPrice: '200000.50',
          quantity: 1,
        ),
      ],
    );

    final api = _FakeOrderApi((status) async => [order]);

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();

    expect(find.text('Đơn #99'), findsOneWidget);

    // Tap order card
    await tester.tap(find.text('Đơn #99'));
    await tester.pumpAndSettle();

    // Verify detail page
    expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
    expect(find.text('John Wick'), findsOneWidget);
    expect(find.text('0987654321'), findsOneWidget);
    expect(find.text('Chi nhánh VIP'), findsOneWidget);
    expect(find.text('Vợt cầu lông'), findsOneWidget);
    expect(find.text('200.001 đ x 1'), findsOneWidget);

    // Actions should be present because it's PENDING
    expect(find.text('Sẵn sàng nhận hàng'), findsOneWidget);
    expect(find.text('Hoàn tất đơn'), findsOneWidget);
    expect(find.text('Hủy đơn'), findsOneWidget);
  });

  testWidgets('final orders hide status actions', (tester) async {
    final order = Order(
      id: '99',
      customerId: '1',
      branchId: '2',
      status: 'COMPLETED',
      totalAmount: '200000',
      createdAt: DateTime.now(),
    );

    final api = _FakeOrderApi((status) async => [order]);

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đơn #99'));
    await tester.pumpAndSettle();

    expect(find.text('Hoàn tất'), findsWidgets); // Status badge
    expect(find.text('Sẵn sàng nhận hàng'), findsNothing);
    expect(find.text('Hoàn tất đơn'), findsNothing);
    expect(find.text('Hủy đơn'), findsNothing);
  });

  testWidgets(
    'cancellation requires confirmation and updates status successfully',
    (tester) async {
      Order order = Order(
        id: '99',
        customerId: '1',
        branchId: '2',
        status: 'PENDING',
        totalAmount: '200000',
        createdAt: DateTime.now(),
      );

      int updateCallCount = 0;

      final api = _FakeOrderApi((status) async => [order], (id, status) async {
        updateCallCount++;
        order = Order(
          id: '99',
          customerId: '1',
          branchId: '2',
          status: status,
          totalAmount: '200000',
          createdAt: DateTime.now(),
          cancelledAt: DateTime.now(),
        );
        return order;
      });

      await tester.pumpWidget(_app(api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đơn #99'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Hủy đơn'));
      await tester.pumpAndSettle();

      // Verify dialog
      expect(find.text('Xác nhận hủy đơn'), findsOneWidget);
      expect(
        find.text('Bạn có chắc chắn muốn hủy đơn hàng này?'),
        findsOneWidget,
      );

      // Press cancel inside dialog
      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();

      expect(updateCallCount, 0);

      // Tap cancel again
      await tester.tap(find.text('Hủy đơn'));
      await tester.pumpAndSettle();

      // Press confirm
      await tester.tap(find.text('Xác nhận'));
      await tester.pumpAndSettle();

      expect(updateCallCount, 1);
      expect(find.text('Cập nhật trạng thái thành công'), findsOneWidget);
      // Since it pops automatically after success, we should be back at the list page.
      expect(find.text('Quản lý đơn hàng'), findsOneWidget);
    },
  );

  testWidgets('failed update keeps the current page and displays an error', (
    tester,
  ) async {
    final order = Order(
      id: '99',
      customerId: '1',
      branchId: '2',
      status: 'PENDING',
      totalAmount: '200000',
      createdAt: DateTime.now(),
    );

    final api = _FakeOrderApi((status) async => [order], (id, status) async {
      throw const ApiException(statusCode: 400, message: 'Invalid stock');
    });

    await tester.pumpWidget(_app(api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đơn #99'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sẵn sàng nhận hàng'));
    await tester.pumpAndSettle();

    // Since it failed, we are still on the detail page.
    expect(find.text('Chi tiết đơn hàng'), findsOneWidget);
    expect(find.text('Invalid stock'), findsOneWidget); // SnackBar message
  });
}
