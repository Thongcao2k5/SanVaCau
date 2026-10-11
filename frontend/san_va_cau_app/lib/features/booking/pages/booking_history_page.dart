import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_page_components.dart';
import '../data/booking_api.dart';
import '../models/booking.dart';
import 'booking_detail_page.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({this.bookingApi, super.key});

  final BookingApi? bookingApi;

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  late final BookingApi _bookingApi;
  late Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingApi = widget.bookingApi ?? BookingApi();
    _bookingsFuture = _bookingApi.getMyBookings();
  }

  Future<void> _reloadBookings() async {
    final future = _bookingApi.getMyBookings();
    setState(() {
      _bookingsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch đặt sân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reloadBookings,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          final bookings = snapshot.data ?? const <Booking>[];
          Widget content;
          if (snapshot.connectionState == ConnectionState.waiting) {
            content = const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            content = AppStateView(
              icon: Icons.wifi_off_rounded,
              title: 'Có lỗi xảy ra',
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Không thể tải lịch sử đặt sân',
              actionLabel: 'Thử lại',
              onAction: _reloadBookings,
            );
          } else if (bookings.isEmpty) {
            content = AppStateView(
              icon: Icons.calendar_month_outlined,
              title: 'Chưa có lịch đặt sân',
              message: 'Các buổi đặt sân của bạn sẽ xuất hiện tại đây.',
              actionLabel: 'Tải lại',
              onAction: _reloadBookings,
            );
          } else {
            content = RefreshIndicator(
              onRefresh: _reloadBookings,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: bookings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return _BookingCard(
                    booking: booking,
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              BookingDetailPage(booking: booking),
                        ),
                      );
                      if (result == true) await _reloadBookings();
                    },
                  );
                },
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: content,
          );
        },
      ),
    );
  }
}

// ─── Status Badge Colors ────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'BOOKED':
    case 'CONFIRMED':
      return AppColors.success;
    case 'CANCELLED':
      return AppColors.primary;
    case 'COMPLETED':
      return AppColors.info;
    case 'PENDING':
    case 'CHECKED_IN':
      return AppColors.warning;
    default:
      return AppColors.primary;
  }
}

String _statusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'BOOKED':
      return 'Đã đặt';
    case 'CONFIRMED':
      return 'Xác nhận';
    case 'CANCELLED':
      return 'Đã hủy';
    case 'COMPLETED':
      return 'Hoàn thành';
    case 'PENDING':
      return 'Chờ xử lý';
    case 'CHECKED_IN':
      return 'Đã nhận sân';
    default:
      return status;
  }
}

// ─── Booking Card ────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  String _formatMoney(String value) {
    final doubleValue = double.tryParse(value) ?? 0;
    final rounded = doubleValue.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      final reverseIndex = rounded.length - i;
      buffer.write(rounded[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
    }
    return '${buffer.toString()} đ';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không xác định';
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final wd = days[date.weekday % 7];
    return '$wd, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatSlots(List slots) {
    if (slots.isEmpty) return '--';
    final first = slots.first;
    final last = slots.last;
    final start = first.startTime.length >= 5
        ? first.startTime.substring(0, 5)
        : first.startTime;
    final end = last.endTime.length >= 5
        ? last.endTime.substring(0, 5)
        : last.endTime;
    return '$start – $end';
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(booking.status);

    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: sc,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.sports_tennis_rounded,
                          color: sc,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.court.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              booking.branch.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sc.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _statusLabel(booking.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sc,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),

                  // Info chips row
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: _formatDate(booking.bookingDate),
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.access_time_rounded,
                        label: _formatSlots(booking.slots),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Footer row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${booking.slots.length} ca',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '#${booking.id}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Tổng tiền',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            _formatMoney(booking.totalAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
