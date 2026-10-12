import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/admin_shell.dart';
import '../../main/main_shell.dart';
import '../data/auth_api.dart';
import '../models/auth_user.dart';
import 'change_password_page.dart';

typedef CustomerShellBuilder = Widget Function(
  AuthApi authApi,
  VoidCallback onSessionChanged,
);
typedef AdminShellBuilder = Widget Function(
  AuthUser user,
  AuthApi authApi,
  VoidCallback onSessionChanged,
);

class SessionRoleGate extends StatefulWidget {
  const SessionRoleGate({
    super.key,
    this.authApi,
    this.customerShellBuilder,
    this.adminShellBuilder,
    this.changePasswordPageBuilder,
  });

  final AuthApi? authApi;
  final CustomerShellBuilder? customerShellBuilder;
  final AdminShellBuilder? adminShellBuilder;
  final Widget Function(AuthApi authApi)? changePasswordPageBuilder;

  @override
  State<SessionRoleGate> createState() => _SessionRoleGateState();
}

class _SessionRoleGateState extends State<SessionRoleGate> {
  late final AuthApi _authApi;
  _SessionResolution? _resolution;

  @override
  void initState() {
    super.initState();
    _authApi = widget.authApi ?? AuthApi();
    _resolveSession();
  }

  Future<void> _resolveSession() async {
    setState(() => _resolution = null);
    try {
      final user = await _authApi.getProfile();
      if (mounted) setState(() => _resolution = _SessionResolution.user(user));
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _authApi.logout();
        if (mounted) {
          setState(() => _resolution = const _SessionResolution.guest());
        }
      } else if (mounted) {
        setState(() => _resolution = const _SessionResolution.error());
      }
    } catch (_) {
      if (mounted) {
        setState(() => _resolution = const _SessionResolution.error());
      }
    }
  }

  Future<void> _openRequiredPasswordChange() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            widget.changePasswordPageBuilder?.call(_authApi) ??
            ChangePasswordPage(authApi: _authApi),
      ),
    );
    if (changed == true && mounted) _resolveSession();
  }

  Future<void> _logout() async {
    await _authApi.logout();
    if (mounted) _resolveSession();
  }

  @override
  Widget build(BuildContext context) {
    final resolution = _resolution;
    if (resolution == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (resolution.hasError) {
      return _SessionError(onRetry: _resolveSession);
    }

    final user = resolution.user;
    if (user == null || !_isInternalRole(user.role)) {
      return widget.customerShellBuilder?.call(_authApi, _resolveSession) ??
          MainShell(authApi: _authApi, onSessionChanged: _resolveSession);
    }
    if (user.mustChangePassword) {
      return _RequiredPasswordScreen(
        onChangePassword: _openRequiredPasswordChange,
        onLogout: _logout,
      );
    }
    return widget.adminShellBuilder?.call(user, _authApi, _resolveSession) ??
        AdminShell(
          user: user,
          authApi: _authApi,
          onSessionChanged: _resolveSession,
        );
  }
}

bool _isInternalRole(String role) {
  return const {
    'ADMIN',
    'BRANCH_MANAGER',
    'STAFF',
  }.contains(role.toUpperCase());
}

class _SessionResolution {
  const _SessionResolution.user(this.user) : hasError = false;
  const _SessionResolution.guest() : user = null, hasError = false;
  const _SessionResolution.error() : user = null, hasError = true;

  final AuthUser? user;
  final bool hasError;
}

class _SessionError extends StatelessWidget {
  const _SessionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 52,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Không thể kiểm tra phiên đăng nhập',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng kiểm tra kết nối rồi thử lại.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequiredPasswordScreen extends StatelessWidget {
  const _RequiredPasswordScreen({
    required this.onChangePassword,
    required this.onLogout,
  });

  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bảo mật tài khoản')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Icon(
                  Icons.password_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bạn cần đổi mật khẩu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy đổi mật khẩu tạm thời trước khi vào khu vực quản trị.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onChangePassword,
                    child: const Text('Đổi mật khẩu ngay'),
                  ),
                ),
                TextButton(onPressed: onLogout, child: const Text('Đăng xuất')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
