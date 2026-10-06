import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../racket_services/pages/racket_service_page.dart';
import '../data/branch_api.dart';
import '../models/branch.dart';

class BranchListPage extends StatefulWidget {
  const BranchListPage({super.key});

  @override
  State<BranchListPage> createState() => _BranchListPageState();
}

class _BranchListPageState extends State<BranchListPage> {
  late final BranchApi _branchApi;
  late Future<List<Branch>> _branchesFuture;

  @override
  void initState() {
    super.initState();
    _branchApi = BranchApi();
    _branchesFuture = _branchApi.getBranches();
  }

  void _reloadBranches() {
    setState(() {
      _branchesFuture = _branchApi.getBranches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi nhánh')),
      body: FutureBuilder<List<Branch>>(
        future: _branchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.message
                : 'Không thể tải danh sách chi nhánh';

            return _BranchStateMessage(
              icon: Icons.wifi_off_outlined,
              title: 'Có lỗi xảy ra',
              message: message,
              actionText: 'Thử lại',
              onActionPressed: _reloadBranches,
            );
          }

          final branches = snapshot.data ?? const <Branch>[];

          if (branches.isEmpty) {
            return _BranchStateMessage(
              icon: Icons.storefront_outlined,
              title: 'Chưa có chi nhánh',
              message: 'Khi admin thêm chi nhánh, danh sách sẽ hiển thị ở đây.',
              actionText: 'Tải lại',
              onActionPressed: _reloadBranches,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _reloadBranches(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: branches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final branch = branches[index];
                return _BranchCard(
                  branch: branch,
                  onViewServices: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RacketServicePage(initialBranch: branch),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch, required this.onViewServices});

  final Branch branch;
  final VoidCallback onViewServices;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    branch.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BranchInfoRow(
                    icon: Icons.schedule_outlined,
                    text: '${branch.openingTime} - ${branch.closingTime}',
                    emphasized: true,
                  ),
                  if (branch.phone != null && branch.phone!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _BranchInfoRow(
                      icon: Icons.phone_outlined,
                      text: branch.phone!,
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onViewServices,
                    icon: const Icon(Icons.build_outlined),
                    label: const Text('Xem dịch vụ vợt'),
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

class _BranchInfoRow extends StatelessWidget {
  const _BranchInfoRow({
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
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BranchStateMessage extends StatelessWidget {
  const _BranchStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onActionPressed, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}
