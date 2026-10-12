import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/admin/admin_shell.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';

class _FakeAuthApi extends AuthApi {
  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

const _admin = AuthUser(
  id: 'admin-1',
  email: 'admin@example.com',
  fullName: 'Admin Test',
  role: 'ADMIN',
  status: 'ACTIVE',
);

Widget _app({
  required _FakeAuthApi authApi,
  VoidCallback? onSessionChanged,
  AuthUser user = _admin,
}) {
  return MaterialApp(
    home: AdminShell(
      user: user,
      authApi: authApi,
      onSessionChanged: onSessionChanged ?? () {},
      dashboardPage: const Scaffold(body: Text('DASHBOARD')),
      userAppBuilder: (_) => const Scaffold(body: Text('USER APP')),
    ),
  );
}

void main() {
  testWidgets('shows four-tab graphite admin navigation', (tester) async {
    await tester.pumpWidget(_app(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Vận hành'), findsOneWidget);
    expect(find.text('Quản lý'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsOneWidget);

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(navigationBar.backgroundColor, isNot(Colors.white));
  });

  testWidgets('view user app pushes a child route and Back returns to admin', (
    tester,
  ) async {
    await tester.pumpWidget(_app(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem ứng dụng người dùng'));
    await tester.pumpAndSettle();

    expect(find.text('USER APP'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản quản trị'), findsOneWidget);
    expect(find.text('USER APP'), findsNothing);
  });

  testWidgets('logout clears session and notifies root gate', (tester) async {
    final authApi = _FakeAuthApi();
    var sessionChanges = 0;
    await tester.pumpWidget(
      _app(authApi: authApi, onSessionChanged: () => sessionChanges++),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(authApi.logoutCalls, 1);
    expect(sessionChanges, 1);
  });

  testWidgets('connects operations and ADMIN management modules', (
    tester,
  ) async {
    await tester.pumpWidget(_app(authApi: _FakeAuthApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vận hành'));
    await tester.pumpAndSettle();
    expect(find.text('Lịch đặt sân'), findsOneWidget);
    expect(find.text('Đơn hàng'), findsOneWidget);
    expect(find.text('Tồn kho'), findsOneWidget);

    await tester.tap(find.text('Quản lý'));
    await tester.pumpAndSettle();
    expect(find.text('Sản phẩm'), findsOneWidget);
    expect(find.text('Chi nhánh và sân'), findsOneWidget);
    expect(find.text('Nội dung trang chủ'), findsOneWidget);
  });

  testWidgets('hides ADMIN-only management modules from STAFF', (tester) async {
    const staff = AuthUser(
      id: 'staff-1',
      email: 'staff@example.com',
      fullName: 'Staff Test',
      role: 'STAFF',
      status: 'ACTIVE',
      branchId: '1',
    );
    await tester.pumpWidget(_app(authApi: _FakeAuthApi(), user: staff));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quản lý'));
    await tester.pumpAndSettle();

    expect(find.text('Không có chức năng quản lý được cấp'), findsOneWidget);
    expect(find.text('Sản phẩm'), findsNothing);
    expect(find.text('Nội dung trang chủ'), findsNothing);
  });
}
