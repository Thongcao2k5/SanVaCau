import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../branches/data/branch_api.dart';
import '../../branches/models/branch.dart';
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

  List<Branch> _branches = [];
  String? _selectedBranchId;

  final TextEditingController _searchController = TextEditingController();

  bool get isAdmin => widget.role == 'ADMIN';
  bool get canMutate => isAdmin || widget.role == 'BRANCH_MANAGER';
  bool get hasAssignedBranch =>
      widget.assignedBranchId != null && widget.assignedBranchId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _api = widget.inventoryApi ?? AdminInventoryApi();
    _branchApi = widget.branchApi ?? BranchApi();

    _searchController.addListener(_filterBySearch);

    if (!isAdmin) {
      _selectedBranchId = widget.assignedBranchId;
    }

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
    // Role check for missing branchId
    if (!isAdmin && !hasAssignedBranch) {
      if (mounted) {
        setState(() {
          _error =
              'Tài khoản của bạn chưa được gán cho bất kỳ chi nhánh nào. '
              'Vui lòng liên hệ quản trị viên.';
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = <Future>[
        _api.getInventories(branchId: _selectedBranchId),
      ];

      if (isAdmin) {
        futures.add(_branchApi.getBranches());
      }

      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _allInventories = results[0] as List<AdminInventory>;
          if (isAdmin) {
            _branches = results[1] as List<Branch>;
            // Add a synthetic "All" option if needed, but we handle it via null selected branch.
          }
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
    if (!isAdmin && !hasAssignedBranch) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inventories = await _api.getInventories(
        branchId: _selectedBranchId,
      );
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lọc theo chi nhánh',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Chi nhánh',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Tất cả chi nhánh'),
                        ),
                        ..._branches.map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setSheetState(() => _selectedBranchId = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                _selectedBranchId = null;
                              });
                              Navigator.pop(context);
                              _loadInventories();
                            },
                            child: const Text('Xóa bộ lọc'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _loadInventories();
                            },
                            child: const Text('Áp dụng'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa cập nhật';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý tồn kho'),
        centerTitle: true,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterSheet,
              tooltip: 'Lọc chi nhánh',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
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
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderMuted),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: canMutate && (isAdmin || hasAssignedBranch)
          ? FloatingActionButton(
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _allInventories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null && _allInventories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Lỗi: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (isAdmin ||
                  (widget.assignedBranchId != null &&
                      widget.assignedBranchId!.isNotEmpty))
                ElevatedButton(
                  onPressed: _loadInitialData,
                  child: const Text('Thử lại'),
                ),
            ],
          ),
        ),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy tồn kho nào.',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
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
          final branchName = inv.branch?.name ?? 'Unknown Branch';

          return Card(
            elevation: 0,
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isLowStock ? AppColors.warning : AppColors.border,
                width: isLowStock ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: !canMutate
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
                                      color: AppColors.textPrimary,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                variantName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SKU: $sku',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
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
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLowStock
                                  ? AppColors.warning.withValues(alpha: 0.3)
                                  : AppColors.borderMuted,
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
                                      ? AppColors.warning
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Tồn kho',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isLowStock
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.store_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            branchName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.update_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(inv.updatedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
