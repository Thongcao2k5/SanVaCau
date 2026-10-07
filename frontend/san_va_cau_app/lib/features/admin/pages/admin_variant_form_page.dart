import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../products/data/product_api.dart';
import '../../products/models/product_variant.dart';

class AdminVariantFormPage extends StatefulWidget {
  const AdminVariantFormPage({
    super.key,
    required this.productId,
    this.variant,
    this.productApi,
  });

  final String productId;
  final ProductVariant? variant;
  final ProductApi? productApi;

  @override
  State<AdminVariantFormPage> createState() => _AdminVariantFormPageState();
}

class _AdminVariantFormPageState extends State<AdminVariantFormPage> {
  late final ProductApi _api;
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  String? _error;

  late final TextEditingController _skuController;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    _api = widget.productApi ?? ProductApi();

    _skuController = TextEditingController(text: widget.variant?.sku ?? '');
    _nameController = TextEditingController(
      text: widget.variant?.variantName ?? '',
    );
    _priceController = TextEditingController(text: widget.variant?.price ?? '');
    _imageUrlController = TextEditingController(
      text: widget.variant?.imageUrl ?? '',
    );
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final body = <String, dynamic>{
        'productId': widget.productId,
        'sku': _skuController.text.trim(),
        'variantName': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()),
        'imageUrl': _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
      };

      if (widget.variant != null) {
        final saved = await _api.updateAdminVariant(widget.variant!.id, body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật phân loại thành công'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, saved);
        }
      } else {
        final saved = await _api.createAdminVariant(body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo phân loại thành công'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, saved);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.variant != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa phân loại' : 'Thêm phân loại'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),

            TextFormField(
              controller: _skuController,
              decoration: const InputDecoration(
                labelText: 'Mã SKU *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mã SKU';
                }
                return null;
              },
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên phân loại *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên phân loại';
                }
                return null;
              },
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Giá *',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập giá';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Giá phải là số lớn hơn 0';
                }
                return null;
              },
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL Hình ảnh',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              enabled: !_isSubmitting,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (!(Uri.tryParse(value.trim())?.isAbsolute ?? false)) {
                    return 'URL không hợp lệ';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Lưu thay đổi' : 'Tạo phân loại'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
