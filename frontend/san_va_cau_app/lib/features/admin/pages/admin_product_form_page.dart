import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../products/data/product_api.dart';
import '../../products/models/product.dart';

class AdminProductFormPage extends StatefulWidget {
  const AdminProductFormPage({super.key, this.product, this.productApi});

  final Product? product;
  final ProductApi? productApi;

  @override
  State<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<AdminProductFormPage> {
  late final ProductApi _api;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  List<ProductCategory> _categories = [];
  List<ProductBrand> _brands = [];

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;

  String? _selectedCategoryId;
  String? _selectedBrandId;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    _api = widget.productApi ?? ProductApi();

    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.product?.imageUrl ?? '',
    );

    _isFeatured = widget.product?.isFeatured ?? false;
    _selectedCategoryId = widget.product?.categoryId;
    _selectedBrandId = widget.product?.brandId;

    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getCategories(),
        _api.getBrands(),
      ]);

      if (mounted) {
        setState(() {
          _categories = results[0] as List<ProductCategory>;
          _brands = results[1] as List<ProductBrand>;

          if (_selectedCategoryId != null &&
              !_categories.any((c) => c.id == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
          if (_selectedBrandId != null &&
              !_brands.any((b) => b.id == _selectedBrandId)) {
            _selectedBrandId = null;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải dữ liệu: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final body = <String, dynamic>{
        'categoryId': _selectedCategoryId,
        'brandId': _selectedBrandId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        'isFeatured': _isFeatured,
      };

      if (widget.product != null) {
        await _api.updateAdminProduct(widget.product!.id, body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật sản phẩm thành công'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await _api.createAdminProduct(body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo sản phẩm thành công'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
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
    final isEditing = widget.product != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null && _categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOptions,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Form(
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
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tên sản phẩm *',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên sản phẩm';
              }
              return null;
            },
            enabled: !_isSubmitting,
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Danh mục *',
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: _isSubmitting
                ? null
                : (val) {
                    setState(() => _selectedCategoryId = val);
                  },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng chọn danh mục';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String?>(
            initialValue: _selectedBrandId,
            decoration: const InputDecoration(
              labelText: 'Thương hiệu',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Không có')),
              ..._brands.map(
                (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
              ),
            ],
            onChanged: _isSubmitting
                ? null
                : (val) {
                    setState(() => _selectedBrandId = val);
                  },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Mô tả',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
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

          SwitchListTile(
            title: const Text('Sản phẩm nổi bật'),
            value: _isFeatured,
            onChanged: _isSubmitting
                ? null
                : (val) {
                    setState(() => _isFeatured = val);
                  },
          ),

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
                  : Text(
                      widget.product != null ? 'Lưu thay đổi' : 'Tạo sản phẩm',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
