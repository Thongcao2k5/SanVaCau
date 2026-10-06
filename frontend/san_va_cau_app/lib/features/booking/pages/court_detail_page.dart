import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../reviews/widgets/reviews_section.dart';
import '../data/booking_api.dart';
import '../models/court.dart';

class CourtDetailPage extends StatefulWidget {
  const CourtDetailPage({super.key, required this.court});

  final Court court;

  @override
  State<CourtDetailPage> createState() => _CourtDetailPageState();
}

class _CourtDetailPageState extends State<CourtDetailPage> {
  final BookingApi _bookingApi = BookingApi();
  Future<List<CourtPrice>>? _pricesFuture;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  void _fetchPrices() {
    setState(() {
      _pricesFuture = _bookingApi.getCourtPrices(widget.court.id);
    });
  }

  String _formatMoney(double value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < rounded.length; i++) {
      final reverseIndex = rounded.length - i;
      buffer.write(rounded[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.court.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.court.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.location_city,
                    text:
                        'Chi nhánh: ${widget.court.branchName?.isNotEmpty == true ? widget.court.branchName! : widget.court.branchId}',
                  ),
                  if (widget.court.branchAddress?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.place_outlined,
                      text: widget.court.branchAddress!,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _CourtStatusTag(status: widget.court.status),
                  if (widget.court.description != null &&
                      widget.court.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Text(
                      widget.court.description!,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bảng giá',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<CourtPrice>>(
                    future: _pricesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Row(
                          children: [
                            const Expanded(
                              child: Text('Không thể tải bảng giá'),
                            ),
                            TextButton(
                              onPressed: _fetchPrices,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        );
                      }
                      final prices = snapshot.data ?? [];
                      if (prices.isEmpty) {
                        return const Text('Sân này chưa có bảng giá.');
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: prices.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = prices[index];
                          final startTime = p.startTime.length >= 5
                              ? p.startTime.substring(0, 5)
                              : p.startTime;
                          final endTime = p.endTime.length >= 5
                              ? p.endTime.substring(0, 5)
                              : p.endTime;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('$startTime - $endTime'),
                            trailing: Text(
                              _formatMoney(p.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          ReviewsSection(targetType: 'COURT', targetId: widget.court.id),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).pop(widget.court);
            },
            child: const Text('Đặt sân này'),
          ),
        ),
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
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _CourtStatusTag extends StatelessWidget {
  const _CourtStatusTag({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (status) {
      'ACTIVE' => ('Đang hoạt động', AppColors.success, AppColors.successSoft),
      'MAINTENANCE' => (
        'Đang bảo trì',
        AppColors.warning,
        AppColors.warningSoft,
      ),
      _ => ('Tạm ngưng', AppColors.textSecondary, AppColors.surfaceMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}
