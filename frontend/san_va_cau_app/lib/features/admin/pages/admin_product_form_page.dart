import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

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
    if (_isSubmitting) return;
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

    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        backgroundColor: AdminTheme.canvas,
        appBar: AppBar(
          title: Text(isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm'),
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AdminStateView(
        icon: Icons.inventory_2_rounded,
        title: 'Đang tải thông tin sản phẩm',
        isLoading: true,
      );
    }

    if (_error != null && _categories.isEmpty) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: _error!,
        actionLabel: 'Thử lại',
        onAction: _loadOptions,
      );
    }

    return Form(
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
                          icon: Icons.inventory_2_rounded,
                          color: AdminTheme.primary,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Thông tin chính',
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
                      key: const Key('product-name'),
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên sản phẩm *',
                        errorMaxLines: 3,
                      ),
                      textInputAction: TextInputAction.next,
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
                      key: const Key('product-category'),
                      isExpanded: true,
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục *',
                        errorMaxLines: 3,
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
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
                          icon: Icons.article_rounded,
                          color: AdminTheme.primary,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nội dung & hình ảnh',
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
                      'Thông tin bổ sung · không bắt buộc',
                      style: TextStyle(color: AdminTheme.textSecondaryStrong),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String?>(
                      key: const Key('product-brand'),
                      isExpanded: true,
                      initialValue: _selectedBrandId,
                      decoration: const InputDecoration(
                        labelText: 'Thương hiệu',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Không có'),
                        ),
                        ..._brands.map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          ),
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
                      key: const Key('product-description'),
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                      maxLines: 3,
                      enabled: !_isSubmitting,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      key: const Key('product-image-url'),
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
                        if (uri == null || source.contains(RegExp(r'[\s\\]'))) {
                          return 'URL không hợp lệ';
                        }
                        final remote =
                            (uri.scheme == 'http' || uri.scheme == 'https') &&
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
                                .any((part) => part == '.' || part == '..');
                        return remote || local ? null : 'URL không hợp lệ';
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              AdminSurface(
                padding: EdgeInsets.zero,
                child: SwitchListTile(
                  key: const Key('product-featured'),
                  activeThumbColor: AdminTheme.primary,
                  secondary: const Icon(
                    Icons.star_rounded,
                    color: AdminTheme.primary,
                  ),
                  title: const Text('Sản phẩm nổi bật'),
                  subtitle: const Text(
                    'Đưa sản phẩm vào nhóm nổi bật trên trang chủ.',
                    style: TextStyle(color: AdminTheme.textSecondaryStrong),
                  ),
                  value: _isFeatured,
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          setState(() => _isFeatured = val);
                        },
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('product-submit'),
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
                          widget.product != null
                              ? 'Lưu thay đổi'
                              : 'Tạo sản phẩm',
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
