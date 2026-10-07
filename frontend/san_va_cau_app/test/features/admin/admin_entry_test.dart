import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/auth/pages/account_page.dart';
import 'package:san_va_cau_app/features/notifications/data/notification_api.dart';

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi(this.role);
  final String role;

  @override
  Future<AuthUser> getProfile() async {
    return AuthUser(
      id: '1',
      email: 'user@example.com',
      fullName: 'Test User',
      role: role,
      status: 'ACTIVE',
    );
  }
}

class _FakeNotificationApi extends NotificationApi {
  @override
  Future<int> getUnreadCount() async => 0;
}

Widget _app(String role) {
  return MaterialApp(
    home: AccountPage(
      authApi: _FakeAuthApi(role),
      notificationApi: _FakeNotificationApi(),
      adminDashboardPage: const Scaffold(body: Text('Admin Dashboard')),
    ),
  );
}

void main() {
  testWidgets('internal roles can open administration', (tester) async {
    await tester.pumpWidget(_app('ADMIN'));
    await tester.pumpAndSettle();

    expect(find.text('Quản trị hệ thống'), findsOneWidget);
    await tester.tap(find.text('Quản trị hệ thống'));
    await tester.pumpAndSettle();
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('customer cannot see administration entry', (tester) async {
    await tester.pumpWidget(_app('CUSTOMER'));
    await tester.pumpAndSettle();

    expect(find.text('Quản trị hệ thống'), findsNothing);
  });

  testWidgets('BRANCH_MANAGER can see administration entry', (tester) async {
    await tester.pumpWidget(_app('BRANCH_MANAGER'));
    await tester.pumpAndSettle();

    expect(find.text('Quản trị hệ thống'), findsOneWidget);
  });

  testWidgets('STAFF can see administration entry', (tester) async {
    await tester.pumpWidget(_app('STAFF'));
    await tester.pumpAndSettle();

    expect(find.text('Quản trị hệ thống'), findsOneWidget);
  });
}
