import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/addresses/models/customer_address.dart';
import 'package:san_va_cau_app/features/branches/data/branch_api.dart';
import 'package:san_va_cau_app/features/branches/models/branch.dart';
import 'package:san_va_cau_app/features/cart/models/cart.dart';
import 'package:san_va_cau_app/features/orders/data/fulfillment_api.dart';
import 'package:san_va_cau_app/features/orders/data/order_api.dart';
import 'package:san_va_cau_app/features/orders/models/order.dart';
import 'package:san_va_cau_app/features/orders/models/order_fulfillment.dart';
import 'package:san_va_cau_app/features/orders/pages/checkout_page.dart';
import 'package:san_va_cau_app/features/payments/data/payment_api.dart';
import 'package:san_va_cau_app/features/payments/models/payment.dart';
import 'package:san_va_cau_app/features/vouchers/data/voucher_api.dart';
import 'package:san_va_cau_app/features/vouchers/models/voucher_quote.dart';

class _FakeBranchApi extends BranchApi {
  _FakeBranchApi({this.failFirst = false});

  final bool failFirst;
  int callCount = 0;

  @override
  Future<List<Branch>> getBranches() async {
    callCount += 1;
    if (failFirst && callCount == 1) {
      throw const ApiException(
        statusCode: 503,
        message: 'Không thể tải cơ sở lúc này',
      );
    }
    return const [_branch];
  }
}

class _FakeOrderApi extends OrderApi {
  int createCallCount = 0;

  @override
  Future<Order> createOrder({
    required String branchId,
    String? productVariantId,
    int? quantity,
    List<String>? cartItemIds,
  }) async {
    createCallCount += 1;
    return const Order(
      id: 'order-1',
      customerId: 'customer-1',
      branchId: 'branch-1',
      status: 'PENDING',
      totalAmount: '120000',
    );
  }
}

class _FakeFulfillmentApi extends FulfillmentApi {
  int pickupCallCount = 0;
  int deliveryCallCount = 0;
  String? deliveryAddressId;

  @override
  Future<OrderFulfillment> createPickup({required String orderId}) async {
    pickupCallCount += 1;
    return const OrderFulfillment(
      id: 'fulfillment-1',
      orderId: 'order-1',
      fulfillmentType: 'PICKUP',
      status: 'PENDING',
      shippingFee: '0',
    );
  }

  @override
  Future<OrderFulfillment> createDelivery({
    required String orderId,
    required String addressId,
  }) async {
    deliveryCallCount += 1;
    deliveryAddressId = addressId;
    return OrderFulfillment(
      id: 'fulfillment-1',
      orderId: orderId,
      fulfillmentType: 'DELIVERY',
      status: 'PENDING',
      shippingFee: '30000',
      addressLine: _address.addressLine,
    );
  }
}

class _FakePaymentApi extends PaymentApi {
  int createCallCount = 0;

  @override
  Future<Payment> createPayment({
    required String targetType,
    required String targetId,
    required String provider,
  }) async {
    createCallCount += 1;
    return Payment(
      id: 'payment-1',
      targetType: targetType,
      targetId: targetId,
      provider: provider,
      amount: '120000',
      status: 'PENDING',
      createdAt: DateTime(2026),
    );
  }
}

class _FakeVoucherApi extends VoucherApi {
  int validateCallCount = 0;

  @override
  Future<VoucherQuote> validateOrderVoucher({
    required String code,
    required double amount,
  }) async {
    validateCallCount += 1;
    return const VoucherQuote(
      code: 'GIAM20',
      title: 'Ưu đãi thành viên',
      discountAmount: 20000,
      finalAmount: 100000,
    );
  }
}

const _branch = Branch(
  id: 'branch-1',
  name: 'Cơ sở Quận 1',
  address: '123 Nguyễn Huệ',
  openingTime: '06:00',
  closingTime: '22:00',
  status: 'ACTIVE',
);

const _cart = Cart(
  id: 'cart-1',
  customerId: 'customer-1',
  totalAmount: 120000,
  items: [
    CartItem(
      id: 'item-1',
      productVariantId: 'variant-1',
      quantity: 1,
      unitPrice: 120000,
      lineTotal: 120000,
      variant: CartVariant(
        id: 'variant-1',
        sku: 'VOT-1',
        variantName: 'Đỏ',
        price: 120000,
        product: CartProduct(id: 'product-1', name: 'Vợt cầu lông'),
      ),
    ),
  ],
);

const _address = CustomerAddress(
  id: 'address-1',
  recipientName: 'Nguyễn Văn A',
  phone: '0900000000',
  addressLine: '12 Lê Lợi',
  city: 'TP.HCM',
  isDefault: true,
);

void main() {
  testWidgets('retries loading branches after an API error', (tester) async {
    final branchApi = _FakeBranchApi(failFirst: true);

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutPage(cart: _cart, branchApi: branchApi),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải cơ sở lúc này'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(branchApi.callCount, 2);
    expect(find.text('Cơ sở Quận 1'), findsOneWidget);
  });

  testWidgets('creates a pickup order after the user selects a branch', (
    tester,
  ) async {
    final orderApi = _FakeOrderApi();
    final fulfillmentApi = _FakeFulfillmentApi();
    final paymentApi = _FakePaymentApi();

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutPage(
          cart: _cart,
          branchApi: _FakeBranchApi(),
          orderApi: orderApi,
          fulfillmentApi: fulfillmentApi,
          paymentApi: paymentApi,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cơ sở Quận 1'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Đặt hàng'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(orderApi.createCallCount, 1);
    expect(fulfillmentApi.pickupCallCount, 1);
    expect(paymentApi.createCallCount, 1);
    expect(find.text('Đặt hàng thành công'), findsOneWidget);
  });

  testWidgets('applies a voucher and updates the payable total', (
    tester,
  ) async {
    final voucherApi = _FakeVoucherApi();
    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutPage(
          cart: _cart,
          branchApi: _FakeBranchApi(),
          voucherApi: voucherApi,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'GIAM20');
    await tester.tap(find.widgetWithText(FilledButton, 'Áp dụng'));
    await tester.pumpAndSettle();

    expect(voucherApi.validateCallCount, 1);
    expect(find.text('Ưu đãi thành viên'), findsOneWidget);
    expect(find.text('Giảm 20.000 đ'), findsOneWidget);
    expect(find.text('100.000 đ'), findsOneWidget);
  });

  testWidgets('requires an address and creates delivery fulfillment', (
    tester,
  ) async {
    final orderApi = _FakeOrderApi();
    final fulfillmentApi = _FakeFulfillmentApi();
    final paymentApi = _FakePaymentApi();

    await tester.pumpWidget(
      MaterialApp(
        home: CheckoutPage(
          cart: _cart,
          branchApi: _FakeBranchApi(),
          orderApi: orderApi,
          fulfillmentApi: fulfillmentApi,
          paymentApi: paymentApi,
          addressPicker: (_) async => _address,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cơ sở Quận 1'));
    await tester.scrollUntilVisible(
      find.text('Giao tận nơi'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Giao tận nơi'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Đặt hàng'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Chọn địa chỉ nhận hàng'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nguyễn Văn A'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Đặt hàng'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(orderApi.createCallCount, 1);
    expect(fulfillmentApi.deliveryCallCount, 1);
    expect(fulfillmentApi.deliveryAddressId, 'address-1');
    expect(paymentApi.createCallCount, 1);
    expect(find.text('Đặt hàng thành công'), findsOneWidget);
  });
}
