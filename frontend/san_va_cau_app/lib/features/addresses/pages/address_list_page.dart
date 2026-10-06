import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/address_api.dart';
import '../models/customer_address.dart';
import 'address_form_page.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({this.selectionMode = false, super.key});

  final bool selectionMode;

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  final AddressApi _addressApi = AddressApi();
  late Future<List<CustomerAddress>> _addressesFuture;
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _addressesFuture = _addressApi.getAddresses();
  }

  Future<void> _reload() async {
    final future = _addressApi.getAddresses();
    setState(() => _addressesFuture = future);
    await future;
  }

  Future<void> _openForm([CustomerAddress? address]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddressFormPage(address: address)),
    );
    if (changed == true) await _reload();
  }

  Future<void> _setDefault(CustomerAddress address) async {
    if (address.isDefault || _processingId != null) return;
    setState(() => _processingId = address.id);
    try {
      await _addressApi.setDefault(address.id);
      await _reload();
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _delete(CustomerAddress address) async {
    if (_processingId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa chỉ?'),
        content: Text(
          'Bạn có chắc muốn xóa địa chỉ của ${address.recipientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processingId = address.id);
    try {
      await _addressApi.deleteAddress(address.id);
      await _reload();
      _showMessage('Đã xóa địa chỉ');
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'Chọn địa chỉ' : 'Địa chỉ của tôi'),
        actions: [
          IconButton(
            tooltip: 'Thêm địa chỉ',
            onPressed: _openForm,
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<CustomerAddress>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return _AddressState(
              icon: Icons.location_off_outlined,
              title: 'Không thể tải địa chỉ',
              message: error is ApiException
                  ? error.message
                  : 'Vui lòng kiểm tra kết nối và thử lại.',
              onAction: _reload,
            );
          }

          final addresses = snapshot.data ?? const <CustomerAddress>[];
          if (addresses.isEmpty) {
            return _AddressState(
              icon: Icons.add_location_alt_outlined,
              title: 'Chưa có địa chỉ',
              message: 'Thêm địa chỉ để chuẩn bị cho lựa chọn giao hàng.',
              actionLabel: 'Thêm địa chỉ',
              onAction: _openForm,
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return _AddressCard(
                  address: address,
                  isProcessing: _processingId == address.id,
                  selectionMode: widget.selectionMode,
                  onSelect: () => Navigator.of(context).pop(address),
                  onEdit: () => _openForm(address),
                  onSetDefault: () => _setDefault(address),
                  onDelete: () => _delete(address),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Thêm địa chỉ'),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isProcessing,
    required this.selectionMode,
    required this.onSelect,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final CustomerAddress address;
  final bool isProcessing;
  final bool selectionMode;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: selectionMode ? onSelect : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      address.recipientName,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (address.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Mặc định',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                address.phone,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(address.fullAddress, style: const TextStyle(height: 1.4)),
              if (address.note != null && address.note!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Ghi chú: ${address.note}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              if (isProcessing)
                const LinearProgressIndicator()
              else if (selectionMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onSelect,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Chọn địa chỉ'),
                  ),
                )
              else
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Sửa'),
                    ),
                    if (!address.isDefault)
                      TextButton(
                        onPressed: onSetDefault,
                        child: const Text('Đặt mặc định'),
                      ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Xóa địa chỉ',
                      onPressed: onDelete,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressState extends StatelessWidget {
  const _AddressState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onAction,
    this.actionLabel = 'Thử lại',
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
