import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../admin/pages/admin_dashboard_page.dart';
import '../../addresses/pages/address_list_page.dart';
import '../../booking/pages/booking_history_page.dart';
import '../../favorites/pages/favorites_page.dart';
import '../../help/pages/help_center_page.dart';
import '../../notifications/data/notification_api.dart';
import '../../notifications/pages/notifications_page.dart';
import '../../orders/pages/order_history_page.dart';
import '../../payments/pages/payment_history_page.dart';
import '../../reviews/pages/my_reviews_page.dart';
import '../../support/pages/support_ticket_list_page.dart';
import '../data/auth_api.dart';
import '../widgets/auth_primary_button.dart';
import '../models/auth_user.dart';
import 'change_password_page.dart';
import 'forgot_password_page.dart';
import 'profile_edit_page.dart';
import 'registration_otp_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    this.authApi,
    this.notificationApi,
    this.notificationsPage,
    this.myReviewsPage,
    this.adminDashboardPage,
    this.changePasswordPage,
    this.returnAfterAuthentication = false,
    this.onSessionChanged,
  });

  final AuthApi? authApi;
  final NotificationApi? notificationApi;
  final Widget? notificationsPage;
  final Widget? myReviewsPage;
  final Widget? adminDashboardPage;
  final Widget? changePasswordPage;
  final bool returnAfterAuthentication;
  final VoidCallback? onSessionChanged;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final AuthApi _authApi;
  late final NotificationApi _notificationApi;
  Future<AuthUser?>? _profileFuture;
  int? _unreadNotificationCount;

  @override
  void initState() {
    super.initState();
    _authApi = widget.authApi ?? AuthApi();
    _notificationApi = widget.notificationApi ?? NotificationApi();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _profileFuture = _fetchProfile();
    });
  }

  Future<AuthUser?> _fetchProfile() async {
    try {
      final user = await _authApi.getProfile();
      if (!user.mustChangePassword) {
        _loadUnreadNotificationCount().ignore();
      }
      return user;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _authApi.logout();
        return null;
      }
      rethrow;
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationApi.getUnreadCount();
      if (mounted) {
        setState(() => _unreadNotificationCount = count);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _unreadNotificationCount = null);
      }
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => widget.notificationsPage ?? const NotificationsPage(),
      ),
    );
    if (mounted) {
      await _loadUnreadNotificationCount();
    }
  }

  void _openMyReviews() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => widget.myReviewsPage ?? const MyReviewsPage(),
      ),
    );
  }

  void _reloadProfile() {
    _loadProfile();
  }

  void _onAuthSuccess() {
    if (!mounted) return;
    if (widget.returnAfterAuthentication) {
      Navigator.of(context).pop(true);
    } else if (widget.onSessionChanged != null) {
      widget.onSessionChanged!();
    } else {
      _reloadProfile();
    }
  }

  Future<void> _logout() async {
    await _authApi.logout();
    if (!mounted) return;
    if (widget.onSessionChanged != null) {
      widget.onSessionChanged!();
      return;
    }
    setState(() {
      _profileFuture = Future<AuthUser?>.value();
      _unreadNotificationCount = null;
    });
  }

  Future<void> _openRequiredPasswordChange() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            widget.changePasswordPage ?? ChangePasswordPage(authApi: _authApi),
      ),
    );
    if (changed == true && mounted) {
      if (widget.onSessionChanged != null) {
        widget.onSessionChanged!();
      } else {
        _reloadProfile();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.returnAfterAuthentication
              ? 'Đăng nhập để đặt sân'
              : 'Tài khoản',
        ),
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
      body: FutureBuilder<AuthUser?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            if (snapshot.data!.mustChangePassword) {
              return _PasswordChangeRequiredView(
                onChangePassword: _openRequiredPasswordChange,
                onLogout: _logout,
              );
            }
            return _ProfileView(
              user: snapshot.data!,
              onLogout: _logout,
              onEditSuccess: _reloadProfile,
              unreadNotificationCount: _unreadNotificationCount,
              onOpenNotifications: _openNotifications,
              onOpenMyReviews: _openMyReviews,
              adminDashboardPage: widget.adminDashboardPage,
            );
          }

          return _AuthForm(authApi: _authApi, onAuthSuccess: _onAuthSuccess);
        },
      ),
    );
  }
}

class _PasswordChangeRequiredView extends StatelessWidget {
  const _PasswordChangeRequiredView({
    required this.onChangePassword,
    required this.onLogout,
  });

  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.password_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bạn cần đổi mật khẩu',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hãy đổi mật khẩu tạm thời trước khi sử dụng tài khoản.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onChangePassword,
                  child: const Text('Đổi mật khẩu ngay'),
                ),
                TextButton(onPressed: onLogout, child: const Text('Đăng xuất')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.user,
    required this.onLogout,
    required this.onEditSuccess,
    required this.unreadNotificationCount,
    required this.onOpenNotifications,
    required this.onOpenMyReviews,
    this.adminDashboardPage,
  });

  final AuthUser user;
  final VoidCallback onLogout;
  final VoidCallback onEditSuccess;
  final int? unreadNotificationCount;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenMyReviews;
  final Widget? adminDashboardPage;

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (user.role) {
      'ADMIN' => 'Quản trị viên',
      'BRANCH_MANAGER' => 'Quản lý chi nhánh',
      'STAFF' => 'Nhân viên',
      _ => 'Khách hàng',
    };

    Future<void> openEditProfile() async {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => ProfileEditPage(user: user)),
      );
      if (result == true) onEditSuccess();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 128),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderMuted),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primarySoft,
                backgroundImage:
                    user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(ApiConfig.resolveMediaUrl(user.avatarUrl))
                    : null,
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 30,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _ProfileChip(
                          icon: Icons.verified_user_outlined,
                          label: roleLabel,
                        ),
                        if (user.phone != null && user.phone!.isNotEmpty)
                          _ProfileChip(
                            icon: Icons.phone_outlined,
                            label: user.phone!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Chỉnh sửa hồ sơ',
                onPressed: openEditProfile,
                icon: const Icon(Icons.edit_outlined, size: 20),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                ),
              ),
            ],
          ),
        ),
        if (_isInternalRole(user.role)) ...[
          const SizedBox(height: 16),
          Card(
            child: _AccountMenuTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Quản trị hệ thống',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        adminDashboardPage ?? const AdminDashboardPage(),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 22),
        _AccountMenuGroup(
          title: 'Tài khoản',
          children: [
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
          ],
        ),
        const SizedBox(height: 20),
        _AccountMenuGroup(
          title: 'Hoạt động của tôi',
          children: [
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
            _AccountMenuTile(
              icon: Icons.rate_review_outlined,
              title: 'Đánh giá của tôi',
              onTap: onOpenMyReviews,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _AccountMenuGroup(
          title: 'Tiện ích',
          children: [
            _AccountMenuTile(
              icon: Icons.notifications_outlined,
              title: 'Thông báo của tôi',
              badgeCount: unreadNotificationCount,
              onTap: onOpenNotifications,
            ),
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
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng xuất'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

bool _isInternalRole(String role) {
  return const {'ADMIN', 'BRANCH_MANAGER', 'STAFF'}.contains(role);
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final iconColors = _menuColors(icon);
    return ListTile(
      minTileHeight: 62,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColors.$2,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: iconColors.$1, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount != null && badgeCount! > 0) ...[
            Badge.count(
              count: badgeCount!,
              backgroundColor: AppColors.primary,
              textColor: AppColors.onPrimary,
            ),
            const SizedBox(width: 8),
          ],
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _AccountMenuGroup extends StatelessWidget {
  const _AccountMenuGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderMuted),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  const Divider(height: 1, indent: 66),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

(Color, Color) _menuColors(IconData icon) {
  if (icon == Icons.calendar_month_outlined ||
      icon == Icons.notifications_outlined) {
    return (AppColors.info, AppColors.infoSoft);
  }
  if (icon == Icons.favorite_border || icon == Icons.rate_review_outlined) {
    return (AppColors.primary, AppColors.primarySoft);
  }
  if (icon == Icons.payments_outlined || icon == Icons.location_on_outlined) {
    return (AppColors.success, AppColors.successSoft);
  }
  if (icon == Icons.receipt_long_outlined || icon == Icons.forum_outlined) {
    return (AppColors.warning, AppColors.warningSoft);
  }
  return (AppColors.textSecondary, AppColors.surfaceMuted);
}

class _AuthForm extends StatefulWidget {
  const _AuthForm({required this.authApi, required this.onAuthSuccess});

  final AuthApi authApi;
  final VoidCallback onAuthSuccess;

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  bool _showPassword = false;
  String? _errorMessage;

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Nhập email';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

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
        await widget.authApi.requestRegistrationOtp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        if (!mounted) return;
        final verified = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => RegistrationOtpPage(
              authApi: widget.authApi,
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _fullNameController.text.trim(),
              phone: _phoneController.text.trim().isEmpty
                  ? null
                  : _phoneController.text.trim(),
            ),
          ),
        );
        if (verified != true) return;
      } else {
        await widget.authApi.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      widget.onAuthSuccess();
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } on SocketException catch (_) {
      setState(() {
        _errorMessage = 'Không thể kết nối máy chủ. Vui lòng kiểm tra server và kết nối mạng.';
      });
    } on http.ClientException catch (_) {
      setState(() {
        _errorMessage = 'Không thể kết nối máy chủ. Vui lòng kiểm tra server và kết nối mạng.';
      });
    } on TimeoutException catch (_) {
      setState(() {
        _errorMessage = 'Máy chủ phản hồi quá lâu. Vui lòng thử lại.';
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33DC2626),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _isRegisterMode
                  ? Icons.person_add_alt_1_rounded
                  : Icons.lock_open_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _isRegisterMode ? 'Tạo tài khoản mới' : 'Chào mừng trở lại',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isRegisterMode
              ? 'Đăng ký để đặt sân và mua sắm thuận tiện hơn'
              : 'Đăng nhập để tiếp tục sử dụng SanVaCau',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 18),
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderMuted),
          ),
          child: Row(
            children: [
              _AuthModeButton(
                label: 'Đăng nhập',
                selected: !_isRegisterMode,
                onTap: () => setState(() {
                  _isRegisterMode = false;
                  _errorMessage = null;
                }),
              ),
              _AuthModeButton(
                label: 'Đăng ký',
                selected: _isRegisterMode,
                onTap: () => setState(() {
                  _isRegisterMode = true;
                  _errorMessage = null;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderMuted),
          ),
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
                      validator: _validateEmail,
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
        if (!_isRegisterMode)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ForgotPasswordPage(authApi: widget.authApi),
                      ),
                    ),
              child: const Text('Quên mật khẩu?'),
            ),
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
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
        const SizedBox(height: 12),
        AuthPrimaryButton(
          label: _isSubmitting
              ? 'Đang xử lý...'
              : (_isRegisterMode ? 'Tạo tài khoản' : 'Đăng nhập'),
          icon: _isRegisterMode
              ? Icons.person_add_alt_1_rounded
              : Icons.arrow_forward_rounded,
          loading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
      ],
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: AppColors.primary.withAlpha(35))
                : null,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x18DC2626),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
