import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_api.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/otp_code_field.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.authApi});

  final AuthApi authApi;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  OtpRequestResult? _request;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _error = 'Email không đúng định dạng');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.authApi.requestPasswordResetOtp(email);
      if (!mounted) return;
      setState(() {
        _request = result;
        _codeController.clear();
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp(String value) async {
    final code = value.trim();
    if (code.length != 6 || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resetToken = await widget.authApi.verifyPasswordResetOtp(
        email: _emailController.text.trim(),
        code: code,
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordPage(
            authApi: widget.authApi,
            resetToken: resetToken,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _codeController.clear();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waitingForOtp = _request != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                waitingForOtp
                    ? Icons.mark_email_read_rounded
                    : Icons.key_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            waitingForOtp ? 'Nhập mã xác nhận' : 'Khôi phục mật khẩu',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            waitingForOtp
                ? 'Mã OTP gồm 6 chữ số đã được gửi đến\n${_emailController.text.trim()}'
                : 'Nhập email đã đăng ký để nhận mã xác nhận.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderMuted),
            ),
            child: waitingForOtp
                ? OtpCodeField(
                    controller: _codeController,
                    enabled: !_loading,
                    onCompleted: _verifyOtp,
                  )
                : TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_loading) _requestOtp();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Email đăng ký',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
          ),
          if (_loading && waitingForOtp) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 8),
            const Text('Đang xác minh mã...', textAlign: TextAlign.center),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 20),
          if (!waitingForOtp)
            AuthPrimaryButton(
              label: _loading ? 'Đang gửi...' : 'Gửi mã OTP',
              icon: Icons.send_rounded,
              loading: _loading,
              onPressed: _loading ? null : _requestOtp,
            )
          else
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: const StadiumBorder(),
                ),
                onPressed: _loading ? null : _requestOtp,
                icon: const Icon(Icons.refresh_rounded, size: 19),
                label: const Text('Gửi lại mã'),
              ),
            ),
        ],
      ),
    );
  }
}
