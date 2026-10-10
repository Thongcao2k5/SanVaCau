import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/auth/pages/change_email_page.dart';
import 'package:san_va_cau_app/features/auth/widgets/auth_primary_button.dart';

class _FakeAuthApi extends AuthApi {
  String? requestedEmail;
  String? verifiedEmail;
  String? verifiedCode;

  @override
  Future<OtpRequestResult> requestEmailChangeOtp(String newEmail) async {
    requestedEmail = newEmail;
    return const OtpRequestResult(
      expiresInSeconds: 300,
      resendAfterSeconds: 60,
    );
  }

  @override
  Future<AuthUser> verifyEmailChangeOtp({
    required String newEmail,
    required String code,
  }) async {
    verifiedEmail = newEmail;
    verifiedCode = code;
    return AuthUser(
      id: '1',
      email: newEmail,
      fullName: 'Test User',
      role: 'CUSTOMER',
      status: 'ACTIVE',
    );
  }
}

void main() {
  testWidgets('requests and automatically verifies an email change OTP', (
    tester,
  ) async {
    final authApi = _FakeAuthApi();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeEmailPage(
          currentEmail: 'old@example.com',
          authApi: authApi,
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'new@example.com');
    await tester.tap(find.widgetWithText(AuthPrimaryButton, 'Gửi mã xác nhận'));
    await tester.pumpAndSettle();

    expect(authApi.requestedEmail, 'new@example.com');
    expect(find.text('Nhập mã OTP'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pumpAndSettle();

    expect(authApi.verifiedEmail, 'new@example.com');
    expect(authApi.verifiedCode, '123456');
  });
}
