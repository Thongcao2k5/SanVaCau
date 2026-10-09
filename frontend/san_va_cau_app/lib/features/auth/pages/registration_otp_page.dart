import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_api.dart';

class RegistrationOtpPage extends StatefulWidget {
  const RegistrationOtpPage({
    super.key,
    required this.authApi,
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.initialResult,
  });

  final AuthApi authApi;
  final String email;
  final String password;
  final String fullName;
  final String? phone;
  final OtpRequestResult initialResult;

  @override
  State<RegistrationOtpPage> createState() => _RegistrationOtpPageState();
}

class _RegistrationOtpPageState extends State<RegistrationOtpPage> {
  final _codeController = TextEditingController();
  late OtpRequestResult _result = widget.initialResult;
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
      final result = await widget.authApi.requestRegistrationOtp(
        email: widget.email,
        password: widget.password,
        fullName: widget.fullName,
        phone: widget.phone,
      );
      setState(() => _result = result);
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
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 64),
        const SizedBox(height: 16),
        Text(
          'Nhập mã OTP đã gửi đến\n${widget.email}',
          textAlign: TextAlign.center,
        ),
        if (_result.debugOtp != null) ...[
          const SizedBox(height: 12),
          Text(
            'Mã thử nghiệm: ${_result.debugOtp}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(labelText: 'Mã OTP'),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _loading ? null : _verify,
          child: Text(_loading ? 'Đang xử lý...' : 'Xác nhận đăng ký'),
        ),
        TextButton(
          onPressed: _loading ? null : _resend,
          child: const Text('Gửi lại mã'),
        ),
      ],
    ),
  );
}
