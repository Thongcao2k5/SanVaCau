import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_image.dart';
import '../../booking/data/booking_api.dart';
import '../../booking/models/court.dart';
import '../models/branch.dart';

class BranchDetailPage extends StatefulWidget {
  const BranchDetailPage({
    super.key,
    required this.branch,
    required this.onBookPressed,
  });

  final Branch branch;
  final VoidCallback onBookPressed;

  @override
  State<BranchDetailPage> createState() => _BranchDetailPageState();
}

class _BranchDetailPageState extends State<BranchDetailPage> {
  late final Future<List<Court>> _courtsFuture;

  @override
  void initState() {
    super.initState();
    _courtsFuture = BookingApi().getCourts(branchId: widget.branch.id);
  }

  @override
  Widget build(BuildContext context) {
    final branch = widget.branch;
    final description = branch.description?.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết chi nhánh')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: widget.onBookPressed,
          icon: const Icon(Icons.event_available_rounded),
          label: const Text('Đặt sân tại chi nhánh này'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AppImage(
              source: branch.imageUrl ?? '',
              fit: BoxFit.cover,
              fallback: Container(
                color: AppColors.surfaceMuted,
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        branch.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Chip(
                      avatar: Icon(Icons.circle, size: 10),
                      label: Text('Đang hoạt động'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (description != null && description.isNotEmpty) ...[
                  Text(
                    'Giới thiệu',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          text: branch.address,
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.schedule_rounded,
                          text:
                              '${_shortTime(branch.openingTime)} - ${_shortTime(branch.closingTime)}',
                        ),
                        if (branch.phone?.isNotEmpty == true) ...[
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            text: branch.phone!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sân tại chi nhánh',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<Court>>(
                  future: _courtsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const _CourtMessage(
                        icon: Icons.cloud_off_outlined,
                        text: 'Không thể tải danh sách sân',
                      );
                    }

                    final courts = snapshot.data ?? const <Court>[];
                    if (courts.isEmpty) {
                      return const _CourtMessage(
                        icon: Icons.sports_tennis_outlined,
                        text: 'Chi nhánh chưa có sân đang hoạt động',
                      );
                    }

                    return Card(
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < courts.length;
                            index++
                          ) ...[
                            ListTile(
                              leading: const Icon(
                                Icons.sports_tennis_rounded,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                courts[index].name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle:
                                  courts[index].description?.isNotEmpty == true
                                  ? Text(
                                      courts[index].description!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                            ),
                            if (index < courts.length - 1)
                              const Divider(height: 1, indent: 56),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortTime(String value) {
    return value.length >= 5 ? value.substring(0, 5) : value;
  }
}

class _CourtMessage extends StatelessWidget {
  const _CourtMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textPrimary, height: 1.4),
          ),
        ),
      ],
    );
  }
}
