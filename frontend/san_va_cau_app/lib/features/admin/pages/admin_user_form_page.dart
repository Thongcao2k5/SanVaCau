import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../branches/data/branch_api.dart';
import '../../branches/models/branch.dart';
import '../data/admin_user_api.dart';

class AdminUserFormPage extends StatefulWidget {
  const AdminUserFormPage({super.key, this.branchApi, this.userApi});

  final BranchApi? branchApi;
  final AdminUserApi? userApi;

  @override
  State<AdminUserFormPage> createState() => _AdminUserFormPageState();
}

class _AdminUserFormPageState extends State<AdminUserFormPage> {
  late final BranchApi _branchApi;
  late final AdminUserApi _api;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedRole;
  String? _selectedBranchId;

  List<Branch> _branches = [];
  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _error;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _branchApi = widget.branchApi ?? BranchApi();
    _api = widget.userApi ?? AdminUserApi();
    _loadBranches();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = await _branchApi.getBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          _isLoadingData = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải danh sách chi nhánh: ${e.message}';
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách chi nhánh. Vui lòng thử lại.';
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      setState(() => _error = 'Vui lòng chọn vai trò');
      return;
    }
    if (_selectedBranchId == null) {
      setState(() => _error = 'Vui lòng chọn chi nhánh');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await _api.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole!,
        branchId: _selectedBranchId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo tài khoản thành công')),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          if (e.statusCode == 409) {
            _error = 'Email này đã được sử dụng';
          } else {
            _error = 'Lỗi: ${e.message}';
          }
          _isSubmitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tạo tài khoản. Vui lòng thử lại.';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Thêm tài khoản')),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ tên *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!val.contains('@')) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Vai trò *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'BRANCH_MANAGER',
                          child: Text('Quản lý chi nhánh'),
                        ),
                        DropdownMenuItem(
                          value: 'STAFF',
                          child: Text('Nhân viên'),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val),
                      validator: (val) =>
                          val == null ? 'Vui lòng chọn vai trò' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Chi nhánh *',
                        border: OutlineInputBorder(),
                      ),
                      items: _branches
                          .map(
                            (b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedBranchId = val),
                      validator: (val) =>
                          val == null ? 'Vui lòng chọn chi nhánh' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu ban đầu *',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
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
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu *',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Thêm tài khoản'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
