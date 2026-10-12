import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/booking/data/booking_api.dart';
import 'package:san_va_cau_app/features/booking/models/court.dart';
import 'package:san_va_cau_app/features/branches/data/branch_api.dart';
import 'package:san_va_cau_app/features/branches/models/branch.dart';
import 'package:san_va_cau_app/features/cart/data/cart_api.dart';
import 'package:san_va_cau_app/features/cart/models/cart.dart';
import 'package:san_va_cau_app/features/main/main_shell.dart';

const _shellBranch = Branch(
  id: 'shell-branch-1',
  name: 'Chi nhánh Landmark',
  address: '208 Nguyễn Hữu Cảnh, Bình Thạnh',
  openingTime: '06:00',
  closingTime: '22:00',
  status: 'ACTIVE',
);

class _NavigationBranchApi extends BranchApi {
  @override
  Future<List<Branch>> getBranches() async => const [_shellBranch];
}

class _NavigationBookingApi extends BookingApi {
  @override
  Future<List<Court>> getCourts({String? branchId}) async => const [
    Court(
      id: 'court-shell-1',
      branchId: 'shell-branch-1',
      name: 'Sân Trung Tâm',
      status: 'ACTIVE',
    ),
  ];

  @override
  Future<List<BookingSlot>> getAvailability({
    required String courtId,
    required String date,
  }) async => const [];
}

class _NavigationCartApi extends CartApi {
  @override
  Future<Cart> getCart() async => _cartWithItem;
}

const _cartWithItem = Cart(
  id: '1',
  customerId: '7',
  items: [
    CartItem(
      id: '11',
      productVariantId: '21',
      quantity: 1,
      unitPrice: 120000,
      lineTotal: 120000,
      variant: CartVariant(
        id: '21',
        sku: 'VOT-01',
        variantName: '4U',
        price: 120000,
        product: CartProduct(id: '31', name: 'Vợt cầu lông'),
      ),
    ),
  ],
  totalAmount: 120000,
);

class _SessionAuth extends AuthApi {
  bool loggedIn = false;
  static const user = AuthUser(
    id: '1',
    email: 'customer@example.com',
    fullName: 'Khách đã đăng nhập',
    role: 'CUSTOMER',
    status: 'ACTIVE',
  );
  @override
  Future<AuthUser> getProfile() async {
    if (!loggedIn) {
      throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
    }
    return user;
  }

  @override
  Future<void> logout() async {}
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    loggedIn = true;
    return const AuthSession(user: user, token: 'test');
  }
}

void main() {
  testWidgets('Back requires a second attempt within two seconds to exit', (
    tester,
  ) async {
    final platformCalls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: MainShell(authApi: _SessionAuth())),
    );
    await tester.pump();
    tester.takeException();
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(
      find.text('Vuốt hoặc bấm quay lại lần nữa để thoát'),
      findsOneWidget,
    );
    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(platformCalls, contains('SystemNavigator.pop'));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Account reflects login performed outside the account tab', (
    tester,
  ) async {
    final auth = _SessionAuth();
    await tester.pumpWidget(MaterialApp(home: MainShell(authApi: auth)));
    await tester.pump();
    tester.takeException();
    await tester.pump();
    await auth.login(email: 'customer@example.com', password: 'Customer123');
    await tester.tap(find.text('Tài khoản').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('Khách đã đăng nhập'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsNothing);
  });
  group('MainShell bottom navigation', () {
    testWidgets('contains five destinations in correct order', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: MainShell(authApi: _SessionAuth())),
      );
      await tester.pump();
      tester.takeException();
      await tester.pump();

      // Verify all five destination labels exist.
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Sản phẩm'), findsWidgets);
      expect(find.text('Đặt sân'), findsWidgets);
      expect(find.text('Giỏ hàng'), findsOneWidget);
      expect(find.text('Tài khoản'), findsOneWidget);

      // Verify the animated notch navigation component exists.
      expect(find.byType(AnimatedNotchBottomBar), findsOneWidget);
    });

    testWidgets('preserves selected tab via IndexedStack', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: MainShell(authApi: _SessionAuth())),
      );
      await tester.pump();
      tester.takeException();
      await tester.pump();

      // Verify IndexedStack is used.
      expect(find.byType(IndexedStack), findsOneWidget);

      // Tap on "Sản phẩm" tab (index 1).
      final navBar = find.byType(AnimatedNotchBottomBar);
      expect(navBar, findsOneWidget);

      await tester.tap(find.text('Sản phẩm').last);
      await tester.pump(const Duration(milliseconds: 400));

      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 1);
    });

    testWidgets('home tab is selected by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: MainShell(authApi: _SessionAuth())),
      );
      await tester.pump();
      tester.takeException();
      await tester.pump();

      // The IndexedStack should have index 0 by default.
      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 0);
    });

    testWidgets(
      'hides navigation while selected cart items show checkout summary',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MainShell(
              authApi: _SessionAuth(),
              cartApi: _NavigationCartApi(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Giỏ hàng').last);
        await tester.pumpAndSettle();
        expect(find.byType(AnimatedNotchBottomBar), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Thanh toán'), findsNothing);

        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilledButton, 'Thanh toán'), findsOneWidget);
        expect(find.byType(AnimatedNotchBottomBar), findsNothing);

        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();
        expect(find.widgetWithText(FilledButton, 'Thanh toán'), findsNothing);
        expect(find.byType(AnimatedNotchBottomBar), findsOneWidget);
      },
    );

    testWidgets('product cart icon switches to the existing cart tab', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MainShell(
            authApi: _SessionAuth(),
            cartApi: _NavigationCartApi(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sản phẩm').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Giỏ hàng'));
      await tester.pumpAndSettle();

      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 3);
      expect(find.text('Giỏ hàng (1)'), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(MainShell))).canPop(),
        isFalse,
      );
    });

    testWidgets(
      'branch flow from branch list to detail and booking selects branch tab in MainShell',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MainShell(
              authApi: _SessionAuth(),
              cartApi: _NavigationCartApi(),
              branchApi: _NavigationBranchApi(),
              bookingApi: _NavigationBookingApi(),
            ),
          ),
        );
        await tester.pump();
        tester.takeException();
        await tester.pumpAndSettle();

        // Tap quick action "Chi nhánh"
        await tester.tap(find.text('Chi nhánh').first);
        await tester.pumpAndSettle();

        expect(find.text('Chi nhánh Landmark'), findsOneWidget);

        // Tap on branch card to open BranchDetailPage
        await tester.tap(find.text('Chi nhánh Landmark'));
        await tester.pumpAndSettle();

        expect(find.text('Chi tiết chi nhánh'), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Đặt sân ngay'),
          findsOneWidget,
        );

        // Tap "Đặt sân ngay"
        await tester.tap(find.widgetWithText(FilledButton, 'Đặt sân ngay'));
        await tester.pumpAndSettle();

        // Should return to MainShell, switched to Booking tab (index 2)
        final indexedStack = tester.widget<IndexedStack>(
          find.byType(IndexedStack),
        );
        expect(indexedStack.index, 2);

        // Timeline is active for that branch, user is not asked to pick branch again
        expect(find.text('Chi nhánh Landmark'), findsOneWidget);
        expect(find.text('Bạn muốn chơi ở đâu?'), findsNothing);

        // Bottom navigation is hidden while viewing the booking timeline
        expect(find.byType(AnimatedNotchBottomBar), findsNothing);

        // Back from timeline returns to branch picker in Booking tab and reveals bottom navigation
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(find.text('Bạn muốn chơi ở đâu?'), findsOneWidget);
        expect(find.byType(AnimatedNotchBottomBar), findsOneWidget);
        final currentStack = tester.widget<IndexedStack>(
          find.byType(IndexedStack),
        );
        expect(currentStack.index, 2);
      },
    );
  });
}
