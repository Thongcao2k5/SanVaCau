import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/auth/data/auth_api.dart';
import 'package:san_va_cau_app/features/auth/models/auth_user.dart';
import 'package:san_va_cau_app/features/auth/pages/forgot_password_page.dart';
import 'package:san_va_cau_app/features/auth/pages/registration_otp_page.dart';
import 'package:san_va_cau_app/features/auth/pages/reset_password_page.dart';

class _FakeAuthApi extends AuthApi {
  int registrationVerifyCount = 0;
  int passwordOtpRequestCount = 0;
  int passwordOtpVerifyCount = 0;
  int resetPasswordCount = 0;
  String? resetToken;
  String? newPassword;

  @override
  Future<AuthSession> verifyRegistrationOtp({
    required String email,
    required String code,
  }) async {
    registrationVerifyCount += 1;
    return const AuthSession(user: _user, token: 'token');
  }

  @override
  Future<OtpRequestResult> requestPasswordResetOtp(String email) async {
    passwordOtpRequestCount += 1;
    return const OtpRequestResult(
      expiresInSeconds: 300,
      resendAfterSeconds: 60,
    );
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String code,
  }) async {
    passwordOtpVerifyCount += 1;
    return 'reset-token';
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    resetPasswordCount += 1;
    this.resetToken = resetToken;
    this.newPassword = newPassword;
  }
}

const _user = AuthUser(
  id: 'customer-1',
  email: 'customer@example.com',
  fullName: 'Nguyễn Văn A',
  role: 'CUSTOMER',
  status: 'ACTIVE',
);

void main() {
  testWidgets('registration OTP validates six digits before calling API', (
    tester,
  ) async {
    final authApi = _FakeAuthApi();
    await tester.pumpWidget(
      MaterialApp(
        home: RegistrationOtpPage(
          authApi: authApi,
          email: _user.email,
          password: 'Customer123',
          fullName: _user.fullName,
          phone: null,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('Xác nhận đăng ký'));
    await tester.pump();

    expect(find.text('Mã OTP phải gồm 6 chữ số'), findsOneWidget);
    expect(authApi.registrationVerifyCount, 0);
  });

  testWidgets('forgot password verifies OTP and opens reset password page', (
    tester,
  ) async {
    final authApi = _FakeAuthApi();
    await tester.pumpWidget(
      MaterialApp(home: ForgotPasswordPage(authApi: authApi)),
    );

    await tester.enterText(find.byType(TextField), _user.email);
    await tester.tap(find.text('Gửi mã OTP'));
    await tester.pumpAndSettle();
    expect(authApi.passwordOtpRequestCount, 1);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    expect(authApi.passwordOtpVerifyCount, 1);
    expect(find.text('Tạo mật khẩu mới'), findsWidgets);
  });

  testWidgets('reset password validates confirmation and submits token', (
    tester,
  ) async {
    final authApi = _FakeAuthApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordPage(authApi: authApi, resetToken: 'reset-token'),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Customer123');
    await tester.enterText(fields.at(1), 'Customer456');
    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pump();
    expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
    expect(authApi.resetPasswordCount, 0);

    await tester.enterText(fields.at(1), 'Customer123');
    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(authApi.resetPasswordCount, 1);
    expect(authApi.resetToken, 'reset-token');
    expect(authApi.newPassword, 'Customer123');
  });
}
