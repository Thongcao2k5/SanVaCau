import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../branches/data/branch_api.dart';
import '../../branches/models/branch.dart';
import '../data/racket_service_api.dart';
import '../models/branch_racket_service.dart';

class RacketServicePage extends StatefulWidget {
  const RacketServicePage({this.initialBranch, super.key});

  final Branch? initialBranch;

  @override
  State<RacketServicePage> createState() => _RacketServicePageState();
}

class _RacketServicePageState extends State<RacketServicePage> {
  final BranchApi _branchApi = BranchApi();
  final RacketServiceApi _serviceApi = RacketServiceApi();
  late Future<_RacketServiceData> _dataFuture;
  String? _selectedBranchId;

  @override
  void initState() {
    super.initState();
    _selectedBranchId = widget.initialBranch?.id;
    _dataFuture = _loadData();
  }

  Future<_RacketServiceData> _loadData() async {
    final branches = await _branchApi.getBranches();
    if (branches.isEmpty) {
      return const _RacketServiceData(branches: [], services: []);
    }

    final selected = branches.firstWhere(
      (branch) => branch.id == _selectedBranchId,
      orElse: () => branches.first,
    );
    _selectedBranchId = selected.id;
    final services = await _serviceApi.getAvailableServices(selected.id);
    return _RacketServiceData(branches: branches, services: services);
  }

  Future<void> _reload() async {
    final future = _loadData();
    setState(() => _dataFuture = future);
    await future;
  }

  void _selectBranch(String? branchId) {
    if (branchId == null || branchId == _selectedBranchId) return;
    _selectedBranchId = branchId;
    setState(() => _dataFuture = _loadData());
  }

  String _formatMoney(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
      buffer.write(digits[index]);
    }
    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dịch vụ vợt')),
      body: FutureBuilder<_RacketServiceData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return _ServiceState(
              icon: Icons.wifi_off_outlined,
              title: 'Chưa thể tải dịch vụ',
              message: error is ApiException
                  ? error.message
                  : 'Vui lòng kiểm tra kết nối và thử lại.',
              onRetry: _reload,
            );
          }

          final data = snapshot.data ?? const _RacketServiceData();
          if (data.branches.isEmpty) {
            return _ServiceState(
              icon: Icons.storefront_outlined,
              title: 'Chưa có chi nhánh',
              message: 'Dịch vụ sẽ hiển thị khi có chi nhánh hoạt động.',
              onRetry: _reload,
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedBranchId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Chọn chi nhánh',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      items: data.branches
                          .map(
                            (branch) => DropdownMenuItem(
                              value: branch.id,
                              child: Text(
                                branch.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _selectBranch,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Dịch vụ đang cung cấp',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Giá hiển thị là giá tham khảo tại chi nhánh đã chọn.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                if (data.services.isEmpty)
                  const _EmptyServices()
                else
                  ...data.services.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ServiceCard(
                        item: service,
                        formattedPrice: service.referencePrice == null
                            ? 'Liên hệ'
                            : _formatMoney(service.referencePrice!),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RacketServiceData {
  const _RacketServiceData({
    this.branches = const [],
    this.services = const [],
  });

  final List<Branch> branches;
  final List<BranchRacketService> services;
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item, required this.formattedPrice});

  final BranchRacketService item;
  final String formattedPrice;

  @override
  Widget build(BuildContext context) {
    final description = item.description?.trim().isNotEmpty == true
        ? item.description!
        : item.service.description;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ServiceImage(url: item.service.imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.service.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (description != null && description.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _ServiceMeta(
                        icon: Icons.payments_outlined,
                        text: formattedPrice,
                        emphasized: true,
                      ),
                      if (item.estimatedDuration?.trim().isNotEmpty == true)
                        _ServiceMeta(
                          icon: Icons.schedule_outlined,
                          text: item.estimatedDuration!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceImage extends StatelessWidget {
  const _ServiceImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.build_outlined, color: AppColors.primary),
    );
    if (url == null || url!.trim().isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _ServiceMeta extends StatelessWidget {
  const _ServiceMeta({
    required this.icon,
    required this.text,
    this.emphasized = false,
  });

  final IconData icon;
  final String text;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final color = emphasized ? AppColors.primary : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyServices extends StatelessWidget {
  const _EmptyServices();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderMuted),
      ),
      child: const Column(
        children: [
          Icon(Icons.build_circle_outlined, size: 42),
          SizedBox(height: 10),
          Text(
            'Chi nhánh chưa cung cấp dịch vụ vợt',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ServiceState extends StatelessWidget {
  const _ServiceState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRetry;

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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
