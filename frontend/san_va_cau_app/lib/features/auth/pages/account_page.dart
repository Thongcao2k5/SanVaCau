import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../addresses/pages/address_list_page.dart';
import '../../booking/pages/booking_history_page.dart';
import '../../favorites/pages/favorites_page.dart';
import '../../help/pages/help_center_page.dart';
import '../../notifications/pages/notifications_page.dart';
import '../../orders/pages/order_history_page.dart';
import '../../payments/pages/payment_history_page.dart';
import '../../support/pages/support_ticket_list_page.dart';
import '../data/auth_api.dart';
import '../models/auth_user.dart';
import 'change_password_page.dart';
import 'profile_edit_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final AuthApi _authApi = AuthApi();
  Future<AuthUser>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _profileFuture = _authApi.getProfile().catchError((error) async {
        if (error is ApiException &&
            (error.statusCode == 401 || error.statusCode == 403)) {
          await _authApi.logout();
        }
        throw error; // Rethrow to let FutureBuilder know it failed
      });
    });
  }

  void _reloadProfile() {
    _loadProfile();
  }

  Future<void> _logout() async {
    await _authApi.logout();
    _reloadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        actions: [
          IconButton(
            tooltip: 'Trợ giúp',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HelpCenterPage()),
              );
            },
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: FutureBuilder<AuthUser>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return _ProfileView(
              user: snapshot.data!,
              onLogout: _logout,
              onEditSuccess: _reloadProfile,
            );
          }

          return _AuthForm(onAuthSuccess: _reloadProfile);
        },
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.user,
    required this.onLogout,
    required this.onEditSuccess,
  });

  final AuthUser user;
  final VoidCallback onLogout;
  final VoidCallback onEditSuccess;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                _ProfileRow(label: 'Vai trò', value: user.role),
                _ProfileRow(label: 'Trạng thái', value: user.status),
                if (user.phone != null && user.phone!.isNotEmpty)
                  _ProfileRow(label: 'Số điện thoại', value: user.phone!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Tài khoản & Cài đặt',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _AccountMenuTile(
                icon: Icons.edit_outlined,
                title: 'Chỉnh sửa hồ sơ',
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfileEditPage(user: user),
                    ),
                  );
                  if (result == true) {
                    onEditSuccess();
                  }
                },
              ),
              const Divider(height: 1),
              _AccountMenuTile(
                icon: Icons.password_outlined,
                title: 'Đổi mật khẩu',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _AccountMenuTile(
                icon: Icons.location_on_outlined,
                title: 'Địa chỉ của tôi',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const AddressListPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _AccountMenuTile(
                icon: Icons.calendar_month_outlined,
                title: 'Lịch đặt sân của tôi',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BookingHistoryPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _AccountMenuTile(
                icon: Icons.receipt_long_outlined,
                title: 'Đơn hàng của tôi',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OrderHistoryPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _AccountMenuTile(
                icon: Icons.payments_outlined,
                title: 'Lịch sử thanh toán',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const PaymentHistoryPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _AccountMenuTile(
                icon: Icons.notifications_outlined,
                title: 'Thông báo của tôi',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _AccountMenuTile(
                icon: Icons.favorite_border,
                title: 'Yêu thích của tôi',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FavoritesPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _AccountMenuTile(
                icon: Icons.forum_outlined,
                title: 'Yêu cầu hỗ trợ',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const SupportTicketListPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _AccountMenuTile(
                icon: Icons.support_agent_outlined,
                title: 'Trợ giúp & chính sách',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HelpCenterPage(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _AccountMenuTile(
                icon: Icons.logout,
                title: 'Đăng xuất',
                isDestructive: true,
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthForm extends StatefulWidget {
  const _AuthForm({required this.onAuthSuccess});

  final VoidCallback onAuthSuccess;

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final AuthApi _authApi = AuthApi();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await _authApi.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
      } else {
        await _authApi.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      widget.onAuthSuccess();
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Không thể xử lý yêu cầu. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isRegisterMode
                    ? Icons.person_add_alt_1_outlined
                    : Icons.login_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isRegisterMode ? 'Tạo tài khoản' : 'Đăng nhập',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isRegisterMode
                        ? 'Tạo tài khoản để đặt sân và mua sản phẩm.'
                        : 'Đăng nhập để sử dụng đầy đủ các tiện ích.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isRegisterMode) ...[
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Họ tên',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Nhập họ tên'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Nhập email'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Ẩn mật khẩu'
                              : 'Hiện mật khẩu',
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: [
                        _isRegisterMode
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nhập mật khẩu';
                        }

                        if (value.length < 6) {
                          return 'Mật khẩu tối thiểu 6 ký tự';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : Text(_isRegisterMode ? 'Đăng ký' : 'Đăng nhập'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  setState(() {
                    _isRegisterMode = !_isRegisterMode;
                    _errorMessage = null;
                  });
                },
          child: Text(
            _isRegisterMode
                ? 'Đã có tài khoản? Đăng nhập'
                : 'Chưa có tài khoản? Đăng ký',
          ),
        ),
      ],
    );
  }
}
