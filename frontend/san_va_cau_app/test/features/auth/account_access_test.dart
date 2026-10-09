import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/auth/pages/account_page.dart';
import 'package:san_va_cau_app/features/auth/pages/change_password_page.dart';
import 'package:san_va_cau_app/features/notifications/data/notification_api.dart';

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi(this.user);

  final AuthUser user;
  int profileCalls = 0;
  int logoutCalls = 0;

  @override
  Future<AuthUser> getProfile() async {
    profileCalls += 1;
    return user;
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }
}

class _FakeNotificationApi extends NotificationApi {
  @override
  Future<int> getUnreadCount() async => 0;
}

class _LoggedOutAuthApi extends AuthApi {
  @override
  Future<AuthUser> getProfile() async {
    throw const ApiException(statusCode: 401, message: 'Bạn chưa đăng nhập');
  }

  @override
  Future<void> logout() async {}
}

const _staff = AuthUser(
  id: '122',
  email: 'staff@example.com',
  fullName: 'Nhan vien',
  role: 'STAFF',
  status: 'ACTIVE',
);

void main() {
  testWidgets('requires temporary password change before internal access', (
    tester,
  ) async {
    final authApi = _FakeAuthApi(
      const AuthUser(
        id: '122',
        email: 'staff@example.com',
        fullName: 'Nhan vien',
        role: 'STAFF',
        status: 'ACTIVE',
        mustChangePassword: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          authApi: authApi,
          notificationApi: _FakeNotificationApi(),
          adminDashboardPage: const Text('Bang dieu khien'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn cần đổi mật khẩu'), findsOneWidget);
    expect(find.text('Đổi mật khẩu ngay'), findsOneWidget);
    expect(find.text('Quản trị hệ thống'), findsNothing);
    expect(find.text('Bang dieu khien'), findsNothing);
  });

  testWidgets('logout returns to login without requesting profile again', (
    tester,
  ) async {
    final authApi = _FakeAuthApi(_staff);

    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          authApi: authApi,
          notificationApi: _FakeNotificationApi(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(authApi.logoutCalls, 1);
    expect(authApi.profileCalls, 1);
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Quản trị hệ thống'), findsNothing);
  });

  testWidgets('login form rejects a malformed email', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          authApi: _LoggedOutAuthApi(),
          notificationApi: _FakeNotificationApi(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'not-an-email',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mật khẩu'),
      'Password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Email không đúng định dạng'), findsOneWidget);
  });

  testWidgets('change password rejects the current password as the new one', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ChangePasswordPage()));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Password123');
    await tester.enterText(fields.at(1), 'Password123');
    await tester.enterText(fields.at(2), 'Password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Đổi mật khẩu'));
    await tester.pump();

    expect(
      find.text('Mật khẩu mới phải khác mật khẩu hiện tại'),
      findsOneWidget,
    );
  });
}
