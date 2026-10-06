import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/support_api.dart';
import '../models/support_ticket.dart';
import '../support_display.dart';

class SupportTicketFormPage extends StatefulWidget {
  const SupportTicketFormPage({super.key});

  @override
  State<SupportTicketFormPage> createState() => _SupportTicketFormPageState();
}

class _SupportTicketFormPageState extends State<SupportTicketFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final SupportApi _supportApi = SupportApi();

  String _category = 'OTHER';
  String _priority = 'NORMAL';
  bool _isSubmitting = false;

  static const _categories = [
    'ORDER',
    'BOOKING',
    'PAYMENT',
    'ACCOUNT',
    'OTHER',
  ];
  static const _priorities = ['LOW', 'NORMAL', 'HIGH'];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final ticket = await _supportApi.createTicket(
        subject: _subjectController.text,
        message: _messageController.text,
        category: _category,
        priority: _priority,
      );
      if (mounted) Navigator.of(context).pop<SupportTicket>(ticket);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi yêu cầu hỗ trợ.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo yêu cầu hỗ trợ')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Bạn cần hỗ trợ vấn đề gì?',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mô tả rõ vấn đề để đội ngũ xử lý nhanh hơn.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Nhóm vấn đề',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(supportCategoryLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _category = value ?? 'OTHER'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Mức độ ưu tiên',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: _priorities
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(supportPriorityLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _priority = value ?? 'NORMAL'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                maxLength: 200,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  prefixIcon: Icon(Icons.subject_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập tiêu đề'
                    : null,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _messageController,
                minLines: 5,
                maxLines: 8,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Nội dung cần hỗ trợ',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Vui lòng nhập nội dung'
                    : null,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi yêu cầu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
