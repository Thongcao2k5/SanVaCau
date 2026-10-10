import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/auth_api.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/otp_code_field.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({required this.currentEmail, super.key, this.authApi});

  final String currentEmail;
  final AuthApi? authApi;

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  late final AuthApi _authApi;

  bool _otpRequested = false;
  bool _isSubmitting = false;
  int _resendSeconds = 0;
  String? _errorMessage;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _authApi = widget.authApi ?? AuthApi();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim().toLowerCase() ?? '';
    if (email.isEmpty) return 'Vui lòng nhập email mới';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Email không đúng định dạng';
    }
    if (email == widget.currentEmail.toLowerCase()) {
      return 'Email mới phải khác email hiện tại';
    }
    return null;
  }

  void _startCountdown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _resendSeconds = 0);
        return;
      }
      setState(() => _resendSeconds -= 1);
    });
  }

  Future<void> _requestOtp() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final result = await _authApi.requestEmailChangeOtp(
        _emailController.text.trim().toLowerCase(),
      );
      if (!mounted) return;
      setState(() {
        _otpRequested = true;
        _otpController.clear();
      });
      _startCountdown(result.resendAfterSeconds);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Không thể gửi mã OTP. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyOtp(String code) async {
    if (_isSubmitting || code.length != 6) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await _authApi.verifyEmailChangeOtp(
        newEmail: _emailController.text.trim().toLowerCase(),
        code: code,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật email thành công')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        _otpController.clear();
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        _otpController.clear();
        setState(
          () => _errorMessage = 'Không thể xác minh OTP. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thay đổi email')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.mark_email_read_outlined, color: AppColors.info),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mã xác nhận gồm 6 số sẽ được gửi đến email mới. Email chỉ thay đổi sau khi mã được xác minh.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _emailController,
              enabled: !_otpRequested,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              validator: _validateEmail,
              onFieldSubmitted: (_) => _requestOtp(),
              decoration: const InputDecoration(
                labelText: 'Email mới',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
          ),
          if (!_otpRequested) ...[
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: 'Gửi mã xác nhận',
              icon: Icons.send_rounded,
              loading: _isSubmitting,
              onPressed: _requestOtp,
            ),
          ] else ...[
            const SizedBox(height: 24),
            Text(
              'Nhập mã OTP',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Đã gửi đến ${_emailController.text.trim()}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OtpCodeField(
              controller: _otpController,
              enabled: !_isSubmitting,
              onCompleted: _verifyOtp,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _resendSeconds == 0 && !_isSubmitting
                    ? _requestOtp
                    : null,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  _resendSeconds > 0
                      ? 'Gửi lại sau ${_resendSeconds}s'
                      : 'Gửi lại mã',
                ),
              ),
            ),
            if (_isSubmitting) const Center(child: CircularProgressIndicator()),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
