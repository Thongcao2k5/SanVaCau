import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../branches/data/branch_api.dart';
import '../../branches/models/branch.dart';
import '../data/admin_user_api.dart';
import '../models/admin_user.dart';
import 'admin_user_form_page.dart';

class AdminUserListPage extends StatefulWidget {
  const AdminUserListPage({
    super.key,
    required this.role,
    this.userApi,
    this.branchApi,
  });

  final String role;
  final AdminUserApi? userApi;
  final BranchApi? branchApi;

  @override
  State<AdminUserListPage> createState() => _AdminUserListPageState();
}

class _AdminUserListPageState extends State<AdminUserListPage> {
  late final AdminUserApi _api;
  late final BranchApi _branchApi;

  bool _isLoading = true;
  bool _isSubmittingStatus = false;
  bool _isSubmittingPasswordReset = false;
  String? _error;
  List<AdminUser> _allUsers = [];
  List<AdminUser> _displayedUsers = [];
  List<Branch> _branches = [];

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedRole;
  final List<String> _roleOptions = [
    'Tất cả',
    'Quản lý chi nhánh',
    'Nhân viên',
  ];

  @override
  void initState() {
    super.initState();
    _api = widget.userApi ?? AdminUserApi();
    _branchApi = widget.branchApi ?? BranchApi();
    _selectedRole = 'Tất cả';
    if (widget.role == 'ADMIN') {
      _loadData();
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        _api.getUsers(),
        _branchApi.getBranches(),
      ]);

      final allFetchedUsers = futures[0] as List<AdminUser>;
      final branches = futures[1] as List<Branch>;

      if (mounted) {
        setState(() {
          // Display only STAFF and BRANCH_MANAGER
          _allUsers = allFetchedUsers
              .where((u) => u.role == 'STAFF' || u.role == 'BRANCH_MANAGER')
              .toList();
          _branches = branches;
          _isLoading = false;
          _applyFilter();
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải dữ liệu: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải dữ liệu. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    if (_selectedRole == 'Tất cả') {
      _displayedUsers = _allUsers;
    } else if (_selectedRole == 'Quản lý chi nhánh') {
      _displayedUsers = _allUsers
          .where((u) => u.role == 'BRANCH_MANAGER')
          .toList();
    } else if (_selectedRole == 'Nhân viên') {
      _displayedUsers = _allUsers.where((u) => u.role == 'STAFF').toList();
    }
  }

  String _getBranchName(String? branchId) {
    if (branchId == null) return 'Chưa gán';
    try {
      return _branches.firstWhere((b) => b.id == branchId).name;
    } catch (_) {
      return branchId; // fallback safely to branch ID
    }
  }

  String _getRoleLabel(String role) {
    if (role == 'BRANCH_MANAGER') return 'Quản lý chi nhánh';
    if (role == 'STAFF') return 'Nhân viên';
    return role;
  }

  String _getStatusLabel(String status) {
    if (status == 'ACTIVE') return 'Hoạt động';
    if (status == 'LOCKED') return 'Đã khóa';
    if (status == 'INACTIVE') return 'Vô hiệu hóa';
    return status;
  }

  Color _getStatusColor(String status) {
    if (status == 'ACTIVE') return Colors.green;
    if (status == 'LOCKED') return Colors.red;
    if (status == 'INACTIVE') return Colors.grey;
    return AppColors.textSecondary;
  }

  Future<void> _updateStatus(AdminUser user, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(
          'Bạn có chắc chắn muốn thay đổi trạng thái thành ${_getStatusLabel(newStatus)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_isSubmittingStatus) return;
    setState(() {
      _isSubmittingStatus = true;
    });

    if (!mounted) return;
    try {
      await _api.updateUserStatus(userId: user.id, status: newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật trạng thái thành công')),
        );
        _loadData();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: ${e.message}')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật trạng thái. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingStatus = false;
        });
      }
    }
  }

  void _showStatusActions(AdminUser user) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.status != 'ACTIVE')
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Kích hoạt'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(user, 'ACTIVE');
                  },
                ),
              if (user.status != 'LOCKED')
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.red),
                  title: const Text('Khóa tài khoản'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(user, 'LOCKED');
                  },
                ),
              if (user.status != 'INACTIVE')
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.grey),
                  title: const Text('Vô hiệu hóa'),
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(user, 'INACTIVE');
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.password, color: AppColors.primary),
                title: const Text('Đặt lại mật khẩu'),
                onTap: () {
                  Navigator.pop(context);
                  _showResetPasswordDialog(user);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showResetPasswordDialog(AdminUser user) async {
    if (_isSubmittingPasswordReset) return;

    _newPasswordController.clear();
    _confirmPasswordController.clear();
    bool isSubmitting = false;
    bool obscureNew = true;
    bool obscureConfirm = true;
    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => PopScope(
            canPop: !isSubmitting,
            child: AlertDialog(
              title: const Text('Đặt lại mật khẩu'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Mật khẩu mới phải có ít nhất 6 ký tự. Người dùng sẽ được yêu cầu đổi mật khẩu ở lần đăng nhập tiếp theo.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu mới *',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureNew = !obscureNew;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) {
                            return 'Mật khẩu phải từ 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu *',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirm = !obscureConfirm;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val != _newPasswordController.text) {
                            return 'Mật khẩu không khớp';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (_isSubmittingPasswordReset || isSubmitting) {
                            return;
                          }
                          if (!formKey.currentState!.validate()) return;

                          _isSubmittingPasswordReset = true;
                          setDialogState(() => isSubmitting = true);
                          var succeeded = false;

                          try {
                            await _api.resetUserPassword(
                              userId: user.id,
                              newPassword: _newPasswordController.text,
                            );
                            succeeded = true;
                          } on ApiException catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: ${e.message}')),
                              );
                            }
                          } catch (_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Không thể đặt lại mật khẩu. Vui lòng thử lại.',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            _isSubmittingPasswordReset = false;
                            if (!succeeded && dialogContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                          }

                          if (!succeeded ||
                              !mounted ||
                              !dialogContext.mounted) {
                            return;
                          }

                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đặt lại mật khẩu thành công. Yêu cầu đổi mật khẩu đã được thiết lập.',
                              ),
                            ),
                          );
                          _loadData();
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Xác nhận'),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      _isSubmittingPasswordReset = false;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role != 'ADMIN') {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý nhân viên')),
        body: const Center(child: Text('Không có quyền truy cập')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Quản lý nhân viên')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminUserFormPage(
                branchApi: widget.branchApi,
                userApi: widget.userApi,
              ),
            ),
          );
          if (result == true) {
            _loadData();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Lọc theo vai trò',
                      border: OutlineInputBorder(),
                    ),
                    items: _roleOptions
                        .map(
                          (role) =>
                              DropdownMenuItem(value: role, child: Text(role)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRole = val;
                          _applyFilter();
                        });
                      }
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primary,
                    child: _displayedUsers.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text('Không tìm thấy tài khoản nào.'),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16)
                                .copyWith(bottom: 80),
                            itemCount: _displayedUsers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final user = _displayedUsers[index];
                              final branchName = _getBranchName(user.branchId);

                              return Card(
                                elevation: 0,
                                color: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: AppColors.textSecondary.withAlpha(
                                      25,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              user.fullName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.more_vert),
                                            onPressed: () =>
                                                _showStatusActions(user),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Email: ${user.email}'),
                                      if (user.phone != null &&
                                          user.phone!.isNotEmpty)
                                        Text('SĐT: ${user.phone}'),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withAlpha(25),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _getRoleLabel(user.role),
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                user.status,
                                              ).withAlpha(25),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _getStatusLabel(user.status),
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                  user.status,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Chi nhánh: $branchName',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (user.mustChangePassword) ...[
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Yêu cầu đổi mật khẩu ở lần đăng nhập tới',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
