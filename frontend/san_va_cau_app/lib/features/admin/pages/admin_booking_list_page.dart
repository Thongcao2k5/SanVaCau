import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_ui.dart';

import 'package:san_va_cau_app/core/theme/app_colors.dart';
import 'package:san_va_cau_app/features/booking/data/booking_api.dart';
import 'package:san_va_cau_app/features/booking/models/booking.dart';

import 'admin_booking_detail_page.dart';

class AdminBookingListPage extends StatefulWidget {
  const AdminBookingListPage({super.key, this.bookingApi});

  final BookingApi? bookingApi;

  @override
  State<AdminBookingListPage> createState() => _AdminBookingListPageState();
}

class _AdminBookingListPageState extends State<AdminBookingListPage> {
  late final BookingApi _api = widget.bookingApi ?? BookingApi();
  Future<List<Booking>>? _bookingsFuture;

  String _selectedStatus = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      String? dateStr;
      if (_selectedDate != null) {
        dateStr =
            '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      }

      _bookingsFuture = _api.getAdminBookings(
        status: _selectedStatus.isNotEmpty ? _selectedStatus : null,
        date: dateStr,
      );
    });
  }

  Future<void> _refresh() async {
    _loadBookings();
    await _bookingsFuture;
  }

  void _onStatusChanged(String status) {
    if (_selectedStatus == status) return;
    setState(() {
      _selectedStatus = status;
    });
    _loadBookings();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              onSurface: AdminTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadBookings();
    }
  }

  void _clearDate() {
    if (_selectedDate != null) {
      setState(() {
        _selectedDate = null;
      });
      _loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.data(Theme.of(context)),
      child: Scaffold(
        backgroundColor: AdminTheme.canvas,
        appBar: AppBar(
          title: const Text('Quản lý lịch đặt'),
          backgroundColor: AdminTheme.graphite,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildFilters(),
              Expanded(
                child: FutureBuilder<List<Booking>>(
                  future: _bookingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Đang tải lịch đặt sân'),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      return AdminStateView(
                        icon: Icons.cloud_off_rounded,
                        title: 'Không thể tải danh sách lịch đặt sân',
                        message: 'Kiểm tra kết nối rồi thử lại.',
                        actionLabel: 'Thử lại',
                        onAction: _loadBookings,
                      );
                    }

                    final bookings = snapshot.data ?? [];

                    if (bookings.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: const AdminStateView(
                                icon: Icons.event_busy_rounded,
                                title: 'Không có lịch đặt sân nào',
                                message: 'Thử chọn ngày hoặc trạng thái khác.',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: bookings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _BookingCard(
                            booking: bookings[index],
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminBookingDetailPage(
                                    booking: bookings[index],
                                    bookingApi: _api,
                                  ),
                                ),
                              );
                              if (result != null) {
                                _loadBookings();
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AdminTheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(AdminTheme.cardRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AdminTheme.border),
                        borderRadius: BorderRadius.circular(
                          AdminTheme.cardRadius,
                        ),
                        color: AdminTheme.canvas,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: AdminTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'Chọn ngày...'
                                  : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? AdminTheme.textSecondary
                                    : AdminTheme.textPrimary,
                                fontWeight: _selectedDate == null
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clearDate,
                    icon: const Icon(
                      Icons.clear,
                      color: AdminTheme.textSecondary,
                    ),
                    tooltip: 'Xóa ngày',
                  ),
                ],
              ],
            ),
          ),
          // Status Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', ''),
                const SizedBox(width: 8),
                _buildFilterChip('Đã đặt', 'BOOKED'),
                const SizedBox(width: 8),
                _buildFilterChip('Đã nhận sân', 'CHECKED_IN'),
                const SizedBox(width: 8),
                _buildFilterChip('Hoàn tất', 'COMPLETED'),
                const SizedBox(width: 8),
                _buildFilterChip('Đã hủy', 'CANCELLED'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onStatusChanged(value),
      backgroundColor: AdminTheme.canvas,
      selectedColor: AppColors.primarySoft,
      checkmarkColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.transparent),
      ),
      labelStyle: TextStyle(
        fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
        color: isSelected ? AppColors.primaryDark : AdminTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  String _formatCurrency(String amount) {
    final doubleValue = double.tryParse(amount) ?? 0;
    final number = doubleValue.round();
    final text = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(text[i]);
    }
    return '${buffer.toString()} đ';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không xác định';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatSlots(List<BookingTimeSlot> slots) {
    if (slots.isEmpty) return '--';
    final first = slots.first;
    final last = slots.last;
    final start = first.startTime.length >= 5
        ? first.startTime.substring(0, 5)
        : first.startTime;
    final end = last.endTime.length >= 5
        ? last.endTime.substring(0, 5)
        : last.endTime;
    return '$start - $end';
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'BOOKED':
        return 'Đã đặt';
      case 'CHECKED_IN':
        return 'Đã nhận sân';
      case 'COMPLETED':
        return 'Hoàn tất';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  AdminStatusTone _getStatusTone(String status) =>
      switch (status.toUpperCase()) {
        'BOOKED' => AdminStatusTone.success,
        'CHECKED_IN' => AdminStatusTone.warning,
        'COMPLETED' => AdminStatusTone.info,
        'CANCELLED' => AdminStatusTone.danger,
        _ => AdminStatusTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final customerName = booking.customer?.fullName ?? 'Khách vãng lai';
    final customerPhone = booking.customer?.phone ?? '';

    return AdminSurface(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  'Lịch #${booking.id}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AdminStatusBadge(
                  label: _getStatusLabel(booking.status),
                  tone: _getStatusTone(booking.status),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: AdminTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customerPhone.isNotEmpty
                        ? '$customerName - $customerPhone'
                        : customerName,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AdminTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AdminTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${booking.court.name} - ${booking.branch.name}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AdminTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AdminTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ngày: ${_formatDate(booking.bookingDate)}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AdminTheme.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AdminTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ca: ${_formatSlots(booking.slots)} (${booking.slots.length} ca)',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AdminTheme.textPrimary),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AdminTheme.border),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  'Tổng cộng',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AdminTheme.textSecondary),
                ),
                Text(
                  _formatCurrency(booking.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
