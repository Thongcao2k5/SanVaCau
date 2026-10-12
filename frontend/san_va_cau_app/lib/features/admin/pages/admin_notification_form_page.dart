import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import '../../../core/network/api_client.dart';
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
    if (_isSubmitting) return;
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
      return Theme(
        data: AdminTheme.data(Theme.of(context)),
        child: Scaffold(
          appBar: AppBar(title: const Text('Gửi thông báo')),
          body: SafeArea(
            child: const AdminStateView(
              icon: Icons.lock_rounded,
              title: 'Bạn không có quyền truy cập trang này.',
            ),
          ),
        ),
      );
    }

    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gửi thông báo'),
          backgroundColor: AdminTheme.graphite,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: _error != null
              ? AdminStateView(
                  icon: Icons.cloud_off_rounded,
                  title: _error!,
                  actionLabel: 'Thử lại',
                  onAction: () {
                    setState(() {
                      _isLoadingUsers = true;
                      _error = null;
                    });
                    _loadUsers();
                  },
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AdminSurface(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.person_rounded,
                                  color: AdminTheme.warningText,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _userId == null
                                        ? 'Chọn một người nhận. Thông báo sẽ được gửi ngay vào hộp thư của người đó.'
                                        : 'Người nhận: ${_users.firstWhere((u) => u.id == _userId).fullName}. Kiểm tra nội dung trước khi gửi.',
                                    style: const TextStyle(
                                      color: AdminTheme.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isLoadingUsers)
                            const AdminStateView(
                              icon: Icons.hourglass_top_rounded,
                              title: 'Đang tải người nhận',
                              isLoading: true,
                            )
                          else
                            DropdownButtonFormField<String?>(
                              key: ValueKey(_userId),
                              initialValue: _userId,
                              decoration: const InputDecoration(
                                labelText: 'Người nhận *',
                              ),
                              items: _users
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u.id,
                                      child: Text(
                                        '${u.fullName} (${u.role})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isSubmitting
                                  ? null
                                  : (v) => setState(() => _userId = v),
                              validator: (v) =>
                                  v == null ? 'Vui lòng chọn người nhận' : null,
                              isExpanded: true,
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            enabled: !_isSubmitting,
                            scrollPadding: const EdgeInsets.all(32),
                            controller: _typeController,
                            decoration: const InputDecoration(
                              labelText: 'Loại thông báo *',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Không được để trống'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            enabled: !_isSubmitting,
                            scrollPadding: const EdgeInsets.all(32),
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Tiêu đề thông báo *',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Không được để trống'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            enabled: !_isSubmitting,
                            scrollPadding: const EdgeInsets.all(32),
                            controller: _messageController,
                            decoration: const InputDecoration(
                              labelText: 'Nội dung thông báo *',
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Gửi thông báo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
