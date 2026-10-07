import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/admin_content_api.dart';
import '../data/admin_user_api.dart';
import '../models/admin_user.dart';

class AdminNotificationFormPage extends StatefulWidget {
  const AdminNotificationFormPage({
    super.key,
    required this.role,
    this.api,
    this.userApi,
  });

  final String role;
  final AdminContentApi? api;
  final AdminUserApi? userApi;

  @override
  State<AdminNotificationFormPage> createState() =>
      _AdminNotificationFormPageState();
}

class _AdminNotificationFormPageState extends State<AdminNotificationFormPage> {
  late final AdminContentApi _api;
  late final AdminUserApi _userApi;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _typeController = TextEditingController();

  String? _userId;
  List<AdminUser> _users = [];
  bool _isLoadingUsers = true;
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? AdminContentApi();
    _userApi = widget.userApi ?? AdminUserApi();
    _typeController.text = 'SYSTEM';

    if (widget.role == 'ADMIN') {
      _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    try {
      final response = await _userApi.getUsers(page: 1, limit: 100);
      if (mounted) {
        setState(() {
          _users = response;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException
              ? e.message
              : 'Không thể tải danh sách người dùng';
          _isLoadingUsers = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn người nhận')));
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _api.sendNotification(
        userId: _userId!,
        type: _typeController.text.trim(),
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi thông báo thành công')),
        );
        setState(() {
          _titleController.clear();
          _messageController.clear();
          _userId = null;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Không thể gửi thông báo',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.role != 'ADMIN') {
      return Scaffold(
        appBar: AppBar(title: const Text('Gửi thông báo')),
        body: const Center(
          child: Text('Bạn không có quyền truy cập trang này.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi thông báo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoadingUsers = true;
                        _error = null;
                      });
                      _loadUsers();
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Chức năng này dùng để gửi thông báo đẩy và lưu thông báo vào hộp thư của một người dùng cụ thể.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingUsers)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownButtonFormField<String?>(
                      key: ValueKey(_userId),
                      initialValue: _userId,
                      decoration: const InputDecoration(
                        labelText: 'Người nhận *',
                        border: OutlineInputBorder(),
                      ),
                      items: _users
                          .map(
                            (u) => DropdownMenuItem(
                              value: u.id,
                              child: Text('${u.fullName} (${u.role})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _userId = v),
                      validator: (v) =>
                          v == null ? 'Vui lòng chọn người nhận' : null,
                      isExpanded: true,
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: 'Loại thông báo (Type) *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Không được để trống'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề thông báo *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Không được để trống'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung thông báo *',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Không được để trống'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Gửi thông báo'),
                  ),
                ],
              ),
            ),
    );
  }
}
