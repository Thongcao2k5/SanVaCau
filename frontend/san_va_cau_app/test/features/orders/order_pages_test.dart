import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/orders/data/fulfillment_api.dart';
import 'package:san_va_cau_app/features/orders/data/order_api.dart';
import 'package:san_va_cau_app/features/orders/models/order.dart';
import 'package:san_va_cau_app/features/orders/models/order_fulfillment.dart';
import 'package:san_va_cau_app/features/orders/pages/order_detail_page.dart';
import 'package:san_va_cau_app/features/orders/pages/order_history_page.dart';

class _FakeOrderApi extends OrderApi {
  _FakeOrderApi({this.orders = const [], this.listError});

  final List<Order> orders;
  final Object? listError;

  @override
  Future<List<Order>> getMyOrders() async {
    if (listError case final error?) throw error;
    return orders;
  }
}

class _FakeFulfillmentApi extends FulfillmentApi {
  _FakeFulfillmentApi(this.fulfillment);

  final OrderFulfillment? fulfillment;

  @override
  Future<OrderFulfillment?> getForOrder(String orderId) async => fulfillment;
}

const _order = Order(
  id: 'order-1',
  customerId: 'customer-1',
  branchId: 'branch-1',
  status: 'READY_FOR_PICKUP',
  totalAmount: '150000',
  branch: OrderBranch(
    id: 'branch-1',
    name: 'Cơ sở Quận 1',
    address: '123 Nguyễn Huệ',
  ),
  items: [
    OrderItem(
      id: 'item-1',
      productVariantId: 'variant-1',
      productName: 'Vợt cầu lông',
      variantName: 'Đỏ',
      unitPrice: '150000',
      quantity: 1,
    ),
  ],
);

void main() {
  testWidgets('order history shows API errors and lets the user retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderHistoryPage(
          orderApi: _FakeOrderApi(
            listError: const ApiException(
              statusCode: 503,
              message: 'Không thể tải đơn hàng lúc này',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải đơn hàng lúc này'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Thử lại'), findsOneWidget);
  });

  testWidgets('order history renders order status and total', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderHistoryPage(orderApi: _FakeOrderApi(orders: const [_order])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hành trình đơn hàng'), findsNothing);
    expect(find.text('Đơn hàng #order-1'), findsOneWidget);
    expect(find.text('Sẵn sàng nhận'), findsOneWidget);
    expect(find.text('150.000 đ'), findsOneWidget);
  });

  testWidgets('order detail renders delivery fulfillment information', (
    tester,
  ) async {
    const fulfillment = OrderFulfillment(
      id: 'fulfillment-1',
      orderId: 'order-1',
      fulfillmentType: 'DELIVERY',
      status: 'SHIPPING',
      shippingFee: '30000',
      recipientName: 'Nguyễn Văn A',
      phone: '0900000000',
      addressLine: '12 Lê Lợi',
      city: 'TP.HCM',
      trackingCode: 'TRACK-001',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailPage(
          order: _order,
          orderApi: _FakeOrderApi(),
          fulfillmentApi: _FakeFulfillmentApi(fulfillment),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Giao tận nơi'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Giao tận nơi'), findsOneWidget);
    expect(find.text('Đang giao hàng'), findsOneWidget);
    expect(find.text('TRACK-001'), findsOneWidget);
  });
}
