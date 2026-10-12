import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/auth/pages/session_role_gate.dart';

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi({this.user, this.error});

  AuthUser? user;
  Object? error;
  int logoutCalls = 0;

  @override
  Future<AuthUser> getProfile() async {
    if (error case final Object value) throw value;
    return user!;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

AuthUser _user(String role, {bool mustChangePassword = false}) {
  return AuthUser(
    id: 'user-1',
    email: 'user@example.com',
    fullName: 'Test User',
    role: role,
    status: 'ACTIVE',
    mustChangePassword: mustChangePassword,
  );
}

Widget _app(_FakeAuthApi authApi) {
  return MaterialApp(
    home: SessionRoleGate(
      authApi: authApi,
      customerShellBuilder: (_, onSessionChanged) => Scaffold(
        body: Column(
          children: [
            const Text('CUSTOMER SHELL'),
            TextButton(
              onPressed: onSessionChanged,
              child: const Text('REFRESH SESSION'),
            ),
          ],
        ),
      ),
      adminShellBuilder: (user, authApi, onSessionChanged) =>
          Scaffold(body: Text('ADMIN SHELL ${user.role}')),
    ),
  );
}

void main() {
  testWidgets('CUSTOMER enters customer shell', (tester) async {
    await tester.pumpWidget(_app(_FakeAuthApi(user: _user('CUSTOMER'))));
    await tester.pumpAndSettle();

    expect(find.text('CUSTOMER SHELL'), findsOneWidget);
    expect(find.textContaining('ADMIN SHELL'), findsNothing);
  });

  for (final role in const ['ADMIN', 'BRANCH_MANAGER', 'STAFF']) {
    testWidgets('$role enters admin shell', (tester) async {
      await tester.pumpWidget(_app(_FakeAuthApi(user: _user(role))));
      await tester.pumpAndSettle();

      expect(find.text('ADMIN SHELL $role'), findsOneWidget);
      expect(find.text('CUSTOMER SHELL'), findsNothing);
    });
  }

  testWidgets('invalid session is cleared and enters guest shell', (
    tester,
  ) async {
    final authApi = _FakeAuthApi(
      error: const ApiException(statusCode: 401, message: 'Expired'),
    );

    await tester.pumpWidget(_app(authApi));
    await tester.pumpAndSettle();

    expect(authApi.logoutCalls, 1);
    expect(find.text('CUSTOMER SHELL'), findsOneWidget);
  });

  testWidgets('temporary server error does not enter either role shell', (
    tester,
  ) async {
    final authApi = _FakeAuthApi(
      error: const ApiException(statusCode: 500, message: 'Server error'),
    );

    await tester.pumpWidget(_app(authApi));
    await tester.pumpAndSettle();

    expect(find.text('Không thể kiểm tra phiên đăng nhập'), findsOneWidget);
    expect(find.text('CUSTOMER SHELL'), findsNothing);
    expect(find.textContaining('ADMIN SHELL'), findsNothing);
    expect(authApi.logoutCalls, 0);
  });

  testWidgets('internal user must change password before admin shell', (
    tester,
  ) async {
    final authApi = _FakeAuthApi(
      user: _user('STAFF', mustChangePassword: true),
    );

    await tester.pumpWidget(_app(authApi));
    await tester.pumpAndSettle();

    expect(find.text('Bạn cần đổi mật khẩu'), findsOneWidget);
    expect(find.text('Đổi mật khẩu ngay'), findsOneWidget);
    expect(find.textContaining('ADMIN SHELL'), findsNothing);
  });

  testWidgets('session refresh replaces customer shell with admin shell', (
    tester,
  ) async {
    final authApi = _FakeAuthApi(user: _user('CUSTOMER'));
    await tester.pumpWidget(_app(authApi));
    await tester.pumpAndSettle();

    authApi.user = _user('ADMIN');
    await tester.tap(find.text('REFRESH SESSION'));
    await tester.pumpAndSettle();

    expect(find.text('ADMIN SHELL ADMIN'), findsOneWidget);
    expect(find.text('CUSTOMER SHELL'), findsNothing);
  });
}
