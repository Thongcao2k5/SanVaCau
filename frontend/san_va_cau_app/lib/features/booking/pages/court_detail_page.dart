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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.court.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.court.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_city,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Chi nhánh: ${widget.court.branchId}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Trạng thái: ${widget.court.status}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          if (widget.court.description != null &&
              widget.court.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              widget.court.description!,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textPrimary),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

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
                    const Expanded(child: Text('Không thể tải bảng giá')),
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
                separatorBuilder: (context, index) => const Divider(height: 1),
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
                      '${p.price.toInt()}đ',
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
