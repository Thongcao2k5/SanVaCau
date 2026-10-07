import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../branches/data/branch_api.dart';
import '../../branches/models/branch.dart';
import '../../products/data/product_api.dart';
import '../../products/models/product.dart';
import '../../products/models/product_variant.dart';
import '../data/admin_inventory_api.dart';
import '../models/admin_inventory.dart';

class AdminInventoryFormPage extends StatefulWidget {
  const AdminInventoryFormPage({
    super.key,
    required this.role,
    this.assignedBranchId,
    this.inventory,
    this.inventoryApi,
    this.productApi,
    this.branchApi,
  });

  final String role;
  final String? assignedBranchId;
  final AdminInventory? inventory;
  final AdminInventoryApi? inventoryApi;
  final ProductApi? productApi;
  final BranchApi? branchApi;

  @override
  State<AdminInventoryFormPage> createState() => _AdminInventoryFormPageState();
}

class _AdminInventoryFormPageState extends State<AdminInventoryFormPage> {
  late final AdminInventoryApi _api;
  late final ProductApi _productApi;
  late final BranchApi _branchApi;

  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _error;

  List<Branch> _branches = [];
  String? _selectedBranchId;

  List<Product> _products = [];
  String? _selectedProductId;

  List<ProductVariant> _variants = [];
  String? _selectedVariantId;

  bool get isAdmin => widget.role == 'ADMIN';
  bool get isEditing => widget.inventory != null;
  bool get canMutate => isAdmin || widget.role == 'BRANCH_MANAGER';
  bool get hasAssignedBranch =>
      widget.assignedBranchId != null && widget.assignedBranchId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _api = widget.inventoryApi ?? AdminInventoryApi();
    _productApi = widget.productApi ?? ProductApi();
    _branchApi = widget.branchApi ?? BranchApi();

    if (!canMutate) {
      _isLoadingData = false;
      _error = 'Bạn không có quyền chỉnh sửa tồn kho.';
      return;
    }

    if (!isAdmin && !hasAssignedBranch) {
      _isLoadingData = false;
      _error =
          'Tài khoản của bạn chưa được gán cho bất kỳ chi nhánh nào. '
          'Vui lòng liên hệ quản trị viên.';
      return;
    }

    if (isEditing) {
      _quantityController.text = widget.inventory!.quantity.toString();
      _isLoadingData = false;
    } else {
      if (!isAdmin) {
        _selectedBranchId = widget.assignedBranchId;
      }
      _loadFormData();
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoadingData = true;
      _error = null;
    });

    try {
      final futures = <Future>[_productApi.getProducts()];

      if (isAdmin) {
        futures.add(_branchApi.getBranches());
      }

      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _products = (results[0] as List<Product>)
              .where((p) => p.isActive)
              .toList();
          if (isAdmin) {
            _branches = (results[1] as List<Branch>)
                .where((b) => b.status == 'ACTIVE')
                .toList();
          } else {
            // For BRANCH_MANAGER we could optionally fetch branch name if we wanted,
            // but the backend enforces the branchId anyway.
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải dữ liệu: $e';
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _loadVariants(String productId) async {
    setState(() {
      _selectedVariantId = null;
      _variants = [];
      _isLoadingData = true;
      _error = null;
    });

    try {
      final variants = await _productApi.getProductVariants(productId);
      if (mounted) {
        setState(() {
          _variants = variants.where((v) => v.isActive).toList();
          _isLoadingData = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải phân loại: $e';
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!canMutate || (!isAdmin && !hasAssignedBranch)) return;
    if (!_formKey.currentState!.validate()) return;

    if (!isEditing && _selectedBranchId == null) {
      setState(() => _error = 'Vui lòng chọn chi nhánh');
      return;
    }

    if (!isEditing && _selectedVariantId == null) {
      setState(() => _error = 'Vui lòng chọn phân loại sản phẩm');
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;

    if (quantity == 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text(
            'Bạn có chắc chắn muốn đặt số lượng tồn kho bằng 0?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      if (isEditing) {
        await _api.updateInventoryQuantity(
          inventoryId: widget.inventory!.id,
          quantity: quantity,
        );
      } else {
        await _api.createInventory(
          branchId: _selectedBranchId!,
          productVariantId: _selectedVariantId!,
          quantity: quantity,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Cập nhật tồn kho thành công'
                  : 'Thêm tồn kho thành công',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          if (e.statusCode == 409) {
            _error = 'Sản phẩm này đã có trong tồn kho của chi nhánh';
          } else {
            _error = e.toString();
          }
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi kết nối: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Cập nhật tồn kho' : 'Thêm tồn kho'),
        centerTitle: true,
      ),
      body: _isLoadingData && !isEditing
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : !canMutate || (!isAdmin && !hasAssignedBranch)
          ? _buildBlockingError()
          : Form(
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

                  if (isEditing) ...[
                    _buildReadOnlyField(
                      'Chi nhánh',
                      widget.inventory!.branch?.name ??
                          widget.inventory!.branchId,
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyField(
                      'Sản phẩm',
                      widget.inventory!.productVariant?.product?.name ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyField(
                      'Phân loại',
                      widget.inventory!.productVariant?.variantName ?? 'N/A',
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyField(
                      'SKU',
                      widget.inventory!.productVariant?.sku ?? 'N/A',
                    ),
                  ] else ...[
                    if (isAdmin)
                      DropdownButtonFormField<String>(
                        key: const Key('inventory-branch-field'),
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
                        onChanged: (val) {
                          setState(() => _selectedBranchId = val);
                        },
                        validator: (val) =>
                            val == null ? 'Vui lòng chọn chi nhánh' : null,
                      )
                    else
                      _buildReadOnlyField(
                        'Chi nhánh',
                        'Chi nhánh #${widget.assignedBranchId} (Cố định)',
                      ),

                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: const Key('inventory-product-field'),
                      initialValue: _selectedProductId,
                      decoration: const InputDecoration(
                        labelText: 'Sản phẩm *',
                        border: OutlineInputBorder(),
                      ),
                      items: _products
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedProductId = val;
                        });
                        if (val != null) {
                          _loadVariants(val);
                        }
                      },
                      validator: (val) =>
                          val == null ? 'Vui lòng chọn sản phẩm' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_selectedProductId != null)
                      if (_isLoadingData)
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          key: const Key('inventory-variant-field'),
                          initialValue: _selectedVariantId,
                          decoration: const InputDecoration(
                            labelText: 'Phân loại (SKU) *',
                            border: OutlineInputBorder(),
                          ),
                          items: _variants
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v.id,
                                  child: Text('${v.variantName} (${v.sku})'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => _selectedVariantId = val);
                          },
                          validator: (val) =>
                              val == null ? 'Vui lòng chọn phân loại' : null,
                        ),
                  ],

                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('inventory-quantity-field'),
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Số lượng *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Vui lòng nhập số lượng';
                      }
                      final num = int.tryParse(val);
                      if (num == null) return 'Số lượng phải là số nguyên';
                      if (num < 0) return 'Số lượng không được âm';
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('inventory-submit-button'),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Lưu thay đổi' : 'Thêm tồn kho'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        fillColor: AppColors.surfaceMuted,
        filled: true,
      ),
      readOnly: true,
      style: const TextStyle(color: AppColors.textSecondary),
    );
  }

  Widget _buildBlockingError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Bạn không có quyền chỉnh sửa tồn kho.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
