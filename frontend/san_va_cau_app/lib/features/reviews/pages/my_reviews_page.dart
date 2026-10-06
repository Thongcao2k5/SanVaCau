import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../data/review_api.dart';
import '../models/review.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key, this.reviewApi});

  final ReviewApi? reviewApi;

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  late final ReviewApi _reviewApi;
  late Future<ReviewPage> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewApi = widget.reviewApi ?? ReviewApi();
    _reviewsFuture = _reviewApi.getMyReviews();
  }

  Future<void> _reload() async {
    final future = _reviewApi.getMyReviews();
    setState(() {
      _reviewsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá của tôi')),
      body: FutureBuilder<ReviewPage>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return _ReviewListState(
              icon: Icons.rate_review_outlined,
              title: 'Chưa thể tải đánh giá',
              message: error is ApiException
                  ? error.message
                  : 'Vui lòng kiểm tra kết nối và thử lại.',
              actionLabel: 'Thử lại',
              onAction: _reload,
            );
          }

          final reviews = snapshot.data?.items ?? const <Review>[];
          if (reviews.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: const _EmptyReviews(),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _ReviewCard(review: reviews[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final isPublished = review.status == 'PUBLISHED';
    final statusColor = isPublished ? AppColors.success : AppColors.warning;
    final targetName = review.target?.name.isNotEmpty == true
        ? review.target!.name
        : '${_targetTypeLabel(review.targetType)} #${review.targetId}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: review.targetType == 'PRODUCT'
                        ? AppColors.infoSoft
                        : AppColors.successSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    review.targetType == 'PRODUCT'
                        ? Icons.sports_tennis_outlined
                        : Icons.stadium_outlined,
                    color: review.targetType == 'PRODUCT'
                        ? AppColors.info
                        : AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _targetTypeLabel(review.targetType),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPublished ? 'Đã hiển thị' : 'Đã ẩn',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  size: 20,
                  color: AppColors.warning,
                ),
              ),
            ),
            if (review.comment?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(review.comment!, style: const TextStyle(height: 1.45)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.update_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(review.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        const Icon(
          Icons.rate_review_outlined,
          size: 52,
          color: AppColors.primary,
        ),
        const SizedBox(height: 14),
        Text(
          'Bạn chưa có đánh giá nào',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Đánh giá sản phẩm đã mua hoặc sân đã đặt sẽ xuất hiện tại đây.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
      ],
    );
  }
}

class _ReviewListState extends StatelessWidget {
  const _ReviewListState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.primary),
            const SizedBox(height: 14),
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
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

String _targetTypeLabel(String targetType) {
  return targetType == 'PRODUCT' ? 'Sản phẩm' : 'Sân cầu';
}

String _formatDate(DateTime date) {
  final localDate = date.toLocal();
  final day = localDate.day.toString().padLeft(2, '0');
  final month = localDate.month.toString().padLeft(2, '0');
  return '$day/$month/${localDate.year}';
}
