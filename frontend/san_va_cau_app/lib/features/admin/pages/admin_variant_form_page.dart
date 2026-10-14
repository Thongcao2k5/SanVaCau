import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

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
  late final TextEditingController _option1NameController;
  late final TextEditingController _option1ValueController;
  late final TextEditingController _option2NameController;
  late final TextEditingController _option2ValueController;

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
    _option1NameController = TextEditingController(
      text: widget.variant?.option1Name ?? '',
    );
    _option1ValueController = TextEditingController(
      text: widget.variant?.option1Value ?? '',
    );
    _option2NameController = TextEditingController(
      text: widget.variant?.option2Name ?? '',
    );
    _option2ValueController = TextEditingController(
      text: widget.variant?.option2Value ?? '',
    );
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _option1NameController.dispose();
    _option1ValueController.dispose();
    _option2NameController.dispose();
    _option2ValueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
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
        'option1Name': _option1NameController.text.trim().isEmpty
            ? null
            : _option1NameController.text.trim(),
        'option1Value': _option1ValueController.text.trim().isEmpty
            ? null
            : _option1ValueController.text.trim(),
        'option2Name': _option2NameController.text.trim().isEmpty
            ? null
            : _option2NameController.text.trim(),
        'option2Value': _option2ValueController.text.trim().isEmpty
            ? null
            : _option2ValueController.text.trim(),
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

    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        backgroundColor: AdminTheme.canvas,
        appBar: AppBar(
          title: Text(isEditing ? 'Sửa phân loại' : 'Thêm phân loại'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AdminTheme.softWine,
                            borderRadius: BorderRadius.circular(
                              AdminTheme.compactRadius,
                            ),
                            border: Border.all(
                              color: AdminTheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_rounded,
                                color: AdminTheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AdminTheme.primaryText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Các trường có dấu * là bắt buộc.',
                        style: TextStyle(color: AdminTheme.textSecondaryStrong),
                      ),
                    ),
                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              AdminIconBox(
                                icon: Icons.layers_rounded,
                                color: AdminTheme.primary,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Phân loại & giá bán',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AdminTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('variant-sku'),
                            controller: _skuController,
                            decoration: const InputDecoration(
                              labelText: 'Mã SKU *',
                              errorMaxLines: 3,
                            ),
                            textInputAction: TextInputAction.next,
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
                            key: const Key('variant-name'),
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Tên phân loại *',
                              errorMaxLines: 3,
                            ),
                            textInputAction: TextInputAction.next,
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
                            key: const Key('variant-price'),
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Giá *',
                              suffixText: 'đ',
                              errorMaxLines: 3,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Lựa chọn 1',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AdminTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Không bắt buộc · ví dụ Màu / Trắng',
                            style: TextStyle(
                              color: AdminTheme.textSecondaryStrong,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('variant-option1-name'),
                            controller: _option1NameController,
                            decoration: const InputDecoration(
                              labelText: 'Tên lựa chọn 1',
                            ),
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('variant-option1-value'),
                            controller: _option1ValueController,
                            decoration: const InputDecoration(
                              labelText: 'Giá trị lựa chọn 1',
                            ),
                            enabled: !_isSubmitting,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Lựa chọn 2',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AdminTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Không bắt buộc · ví dụ Size / 40',
                            style: TextStyle(
                              color: AdminTheme.textSecondaryStrong,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('variant-option2-name'),
                            controller: _option2NameController,
                            decoration: const InputDecoration(
                              labelText: 'Tên lựa chọn 2',
                            ),
                            enabled: !_isSubmitting,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('variant-option2-value'),
                            controller: _option2ValueController,
                            decoration: const InputDecoration(
                              labelText: 'Giá trị lựa chọn 2',
                            ),
                            enabled: !_isSubmitting,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    AdminSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              AdminIconBox(
                                icon: Icons.image_rounded,
                                color: AdminTheme.primary,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Hình ảnh',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AdminTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ảnh riêng cho phân loại · không bắt buộc',
                            style: TextStyle(
                              color: AdminTheme.textSecondaryStrong,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('variant-image-url'),
                            controller: _imageUrlController,
                            decoration: const InputDecoration(
                              labelText: 'URL Hình ảnh',
                              prefixIcon: Icon(Icons.link_rounded),
                              errorMaxLines: 3,
                            ),
                            keyboardType: TextInputType.url,
                            enabled: !_isSubmitting,
                            validator: (value) {
                              final source = value?.trim() ?? '';
                              if (source.isEmpty) return null;
                              final uri = Uri.tryParse(source);
                              if (uri == null ||
                                  source.contains(RegExp(r'[\s\\]'))) {
                                return 'URL không hợp lệ';
                              }
                              final remote =
                                  (uri.scheme == 'http' ||
                                      uri.scheme == 'https') &&
                                  uri.host.isNotEmpty;
                              // Bundled demo assets and backend upload paths are valid media sources.
                              final local =
                                  !uri.hasScheme &&
                                  !uri.hasAuthority &&
                                  (source.startsWith('assets/') ||
                                      source.startsWith('/')) &&
                                  !uri.path.endsWith('/') &&
                                  uri.query.isEmpty &&
                                  uri.fragment.isEmpty &&
                                  !source
                                      .split('/')
                                      .any(
                                        (part) => part == '.' || part == '..',
                                      );
                              return remote || local
                                  ? null
                                  : 'URL không hợp lệ';
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: const Key('variant-submit'),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AdminTheme.primary,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Flexible(child: Text('Đang lưu…')),
                                ],
                              )
                            : Text(
                                isEditing ? 'Lưu thay đổi' : 'Tạo phân loại',
                              ),
                      ),
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
