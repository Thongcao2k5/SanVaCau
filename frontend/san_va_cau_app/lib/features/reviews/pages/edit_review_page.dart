import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/review_api.dart';
import '../models/review.dart';

class EditReviewPage extends StatefulWidget {
  const EditReviewPage({required this.review, super.key, this.reviewApi});

  final Review review;
  final ReviewApi? reviewApi;

  @override
  State<EditReviewPage> createState() => _EditReviewPageState();
}

class _EditReviewPageState extends State<EditReviewPage> {
  final _formKey = GlobalKey<FormState>();
  late final ReviewApi _reviewApi;
  late final TextEditingController _commentController;
  late int _rating;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reviewApi = widget.reviewApi ?? ReviewApi();
    _commentController = TextEditingController(text: widget.review.comment);
    _rating = widget.review.rating;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await _reviewApi.updateReview(
        reviewId: widget.review.id,
        rating: _rating,
        comment: _commentController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật đánh giá. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetName = widget.review.target?.name.isNotEmpty == true
        ? widget.review.target!.name
        : '${widget.review.targetType == 'PRODUCT' ? 'Sản phẩm' : 'Sân cầu'} #${widget.review.targetId}';

    return Scaffold(
      appBar: AppBar(title: const Text('Sửa đánh giá')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                targetName,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              Text(
                'Mức đánh giá',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  5,
                  (index) => IconButton(
                    tooltip: 'Chọn ${index + 1} sao',
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _rating = index + 1),
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: AppColors.warning,
                      size: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                enabled: !_isSubmitting,
                minLines: 4,
                maxLines: 7,
                maxLength: 1000,
                maxLengthEnforcement: MaxLengthEnforcement.none,
                decoration: const InputDecoration(
                  labelText: 'Nhận xét (tùy chọn)',
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value?.length ?? 0) > 1000
                    ? 'Nhận xét tối đa 1000 ký tự'
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
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
