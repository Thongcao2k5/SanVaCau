import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_api.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/otp_code_field.dart';

class RegistrationOtpPage extends StatefulWidget {
  const RegistrationOtpPage({
    super.key,
    required this.authApi,
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
  });

  final AuthApi authApi;
  final String email;
  final String password;
  final String fullName;
  final String? phone;

  @override
  State<RegistrationOtpPage> createState() => _RegistrationOtpPageState();
}

class _RegistrationOtpPageState extends State<RegistrationOtpPage> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_codeController.text.trim())) {
      setState(() => _error = 'Mã OTP phải gồm 6 chữ số');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authApi.verifyRegistrationOtp(
        email: widget.email,
        code: _codeController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authApi.requestRegistrationOtp(
        email: widget.email,
        password: widget.password,
        fullName: widget.fullName,
        phone: widget.phone,
      );
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Xác nhận email')),
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
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Xác nhận tài khoản',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Mã OTP đã được gửi đến\n${widget.email}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderMuted),
          ),
          child: OtpCodeField(
            controller: _codeController,
            enabled: !_loading,
            onCompleted: (_) => _verify(),
          ),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 12),
        AuthPrimaryButton(
          label: _loading ? 'Đang xử lý...' : 'Xác nhận đăng ký',
          icon: Icons.verified_user_outlined,
          loading: _loading,
          onPressed: _loading ? null : _verify,
        ),
        Center(
          child: TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: const StadiumBorder(),
            ),
            onPressed: _loading ? null : _resend,
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: const Text('Gửi lại mã'),
          ),
        ),
      ],
    ),
  );
}
