import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../branches/data/branch_api.dart';
import '../../products/data/product_api.dart';
import '../data/admin_inventory_api.dart';
import '../models/admin_inventory.dart';
import 'admin_inventory_form_page.dart';

class AdminInventoryListPage extends StatefulWidget {
  const AdminInventoryListPage({
    super.key,
    required this.role,
    this.assignedBranchId,
    this.inventoryApi,
    this.branchApi,
    this.productApi,
  });

  final String role;
  final String? assignedBranchId;
  final AdminInventoryApi? inventoryApi;
  final BranchApi? branchApi;
  final ProductApi? productApi;

  @override
  State<AdminInventoryListPage> createState() => _AdminInventoryListPageState();
}

class _AdminInventoryListPageState extends State<AdminInventoryListPage> {
  late final AdminInventoryApi _api;
  late final BranchApi _branchApi;

  bool _isLoading = true;
  String? _error;
  List<AdminInventory> _allInventories = [];
  List<AdminInventory> _displayedInventories = [];

  final TextEditingController _searchController = TextEditingController();

  bool get isAdmin => widget.role == 'ADMIN';
  bool get canMutate => isAdmin;

  @override
  void initState() {
    super.initState();
    _api = widget.inventoryApi ?? AdminInventoryApi();
    _branchApi = widget.branchApi ?? BranchApi();

    _searchController.addListener(_filterBySearch);

    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBySearch() {
    setState(_applySearch);
  }

  void _applySearch() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _displayedInventories = _allInventories;
      return;
    }

    _displayedInventories = _allInventories.where((inv) {
      final productName = inv.productVariant?.product?.name.toLowerCase() ?? '';
      final variantName = inv.productVariant?.variantName.toLowerCase() ?? '';
      final sku = inv.productVariant?.sku.toLowerCase() ?? '';

      return productName.contains(query) ||
          variantName.contains(query) ||
          sku.contains(query);
    }).toList();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inventories = await _api.getInventories();

      if (mounted) {
        setState(() {
          _allInventories = inventories;
          _isLoading = false;
          _applySearch();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInventories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inventories = await _api.getInventories();
      if (mounted) {
        setState(() {
          _allInventories = inventories;
          _isLoading = false;
          _applySearch();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa cập nhật';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        backgroundColor: AdminTheme.canvas,
        appBar: AppBar(
          title: const Text('Quản lý tồn kho'),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(
              48 * MediaQuery.textScalerOf(context).scale(1) + 12,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                key: const Key('inventory-search-field'),
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, SKU...',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: AdminTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AdminTheme.compactRadius,
                    ),
                    borderSide: const BorderSide(color: AdminTheme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AdminTheme.compactRadius,
                    ),
                    borderSide: const BorderSide(color: AdminTheme.border),
                  ),
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: canMutate
            ? FloatingActionButton(
                tooltip: 'Thêm tồn kho',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminInventoryFormPage(
                        role: widget.role,
                        assignedBranchId: widget.assignedBranchId,
                        inventoryApi: _api,
                        productApi: widget.productApi,
                        branchApi: _branchApi,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadInventories();
                  }
                },
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                child: const Icon(Icons.add),
              )
            : null,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AdminSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kho chung',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        canMutate
                            ? 'Bạn có quyền cập nhật số lượng tồn kho.'
                            : 'Bạn có quyền xem số lượng tồn kho.',
                        style: const TextStyle(color: AdminTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _allInventories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null && _allInventories.isEmpty) {
      return AdminStateView(
        icon: Icons.cloud_off_rounded,
        title: 'Lỗi: $_error',
        actionLabel: 'Thử lại',
        onAction: _loadInitialData,
      );
    }

    if (_displayedInventories.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadInventories,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: const AdminStateView(
              icon: Icons.inventory_2_rounded,
              title: 'Không tìm thấy tồn kho nào.',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInventories,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16).copyWith(bottom: 80),
        itemCount: _displayedInventories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final inv = _displayedInventories[index];
          final isLowStock = inv.quantity <= 5;
          final productName =
              inv.productVariant?.product?.name ?? 'Unknown Product';
          final variantName =
              inv.productVariant?.variantName ?? 'Unknown Variant';
          final sku = inv.productVariant?.sku ?? 'N/A';

          return Card(
            elevation: 0,
            color: AdminTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminTheme.compactRadius),
              side: BorderSide(
                color: isLowStock ? AppColors.warning : AdminTheme.border,
                width: isLowStock ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: !isAdmin
                  ? null
                  : () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminInventoryFormPage(
                            role: widget.role,
                            assignedBranchId: widget.assignedBranchId,
                            inventory: inv,
                            inventoryApi: _api,
                            productApi: widget.productApi,
                            branchApi: _branchApi,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadInventories();
                      }
                    },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AdminTheme.textPrimary,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                variantName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AdminTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SKU: $sku',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AdminTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isLowStock
                                ? AppColors.warningSoft
                                : AdminTheme.canvas,
                            borderRadius: BorderRadius.circular(
                              AdminTheme.compactRadius,
                            ),
                            border: Border.all(
                              color: isLowStock
                                  ? AppColors.warning.withValues(alpha: 0.3)
                                  : AdminTheme.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${inv.quantity}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isLowStock
                                      ? AdminTheme.warningText
                                      : AdminTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Tồn kho',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isLowStock
                                      ? AdminTheme.warningText
                                      : AdminTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (isLowStock) ...[
                      const SizedBox(height: 12),
                      const AdminStatusBadge(
                        label: 'Sắp hết hàng · tồn kho thấp',
                        tone: AdminStatusTone.warning,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          size: 16,
                          color: AdminTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Kho chung',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Icon(
                          Icons.update_rounded,
                          size: 16,
                          color: AdminTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(inv.updatedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
