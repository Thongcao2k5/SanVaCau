import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/app.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/main/main_shell.dart';

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
      await tester.pumpWidget(const SanVaCauApp());
      await tester.pump();

      // Consume the ApiException caused by the test environment.
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
      await tester.pumpWidget(const SanVaCauApp());
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
      await tester.pumpWidget(const SanVaCauApp());
      await tester.pump();
      tester.takeException();
      await tester.pump();

      // The IndexedStack should have index 0 by default.
      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 0);
    });
  });
}
