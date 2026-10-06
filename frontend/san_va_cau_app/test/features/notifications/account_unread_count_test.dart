import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/auth/pages/account_page.dart';
import 'package:san_va_cau_app/features/notifications/data/notification_api.dart';

class _FakeAuthApi extends AuthApi {
  @override
  Future<AuthUser> getProfile() async {
    return const AuthUser(
      id: '1',
      email: 'customer@example.com',
      fullName: 'Khach hang',
      role: 'CUSTOMER',
      status: 'ACTIVE',
    );
  }
}

class _FakeNotificationApi extends NotificationApi {
  _FakeNotificationApi(this.counts);

  final List<int> counts;
  int callCount = 0;

  @override
  Future<int> getUnreadCount() async {
    final index = callCount < counts.length ? callCount : counts.length - 1;
    callCount += 1;
    return counts[index];
  }
}

void main() {
  testWidgets('shows unread badge and refreshes it after notifications close', (
    tester,
  ) async {
    final notificationApi = _FakeNotificationApi([3, 0]);

    await tester.pumpWidget(
      MaterialApp(
        home: AccountPage(
          authApi: _FakeAuthApi(),
          notificationApi: notificationApi,
          notificationsPage: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Quay lại'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thông báo của tôi'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(notificationApi.callCount, 1);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thông báo của tôi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsNothing);
    expect(notificationApi.callCount, 2);
  });
}
