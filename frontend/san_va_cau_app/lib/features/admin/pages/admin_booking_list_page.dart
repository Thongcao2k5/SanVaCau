import 'package:flutter/material.dart';
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
              onSurface: AppColors.textPrimary,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Quản lý lịch đặt'), centerTitle: true),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<Booking>>(
              future: _bookingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Không thể tải danh sách lịch đặt sân'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBookings,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
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
                          child: const Center(
                            child: Text('Không có lịch đặt sân nào'),
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
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppColors.surface,
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderMuted),
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.surfaceMuted,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'Chọn ngày...'
                                  : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
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
                      color: AppColors.textSecondary,
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
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onStatusChanged(value),
      backgroundColor: AppColors.surfaceMuted,
      selectedColor: AppColors.primarySoft,
      checkmarkColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.transparent),
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'BOOKED':
        return AppColors.success;
      case 'CHECKED_IN':
        return AppColors.warning;
      case 'COMPLETED':
        return AppColors.info;
      case 'CANCELLED':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final customerName = booking.customer?.fullName ?? 'Khách vãng lai';
    final customerPhone = booking.customer?.phone ?? '';

    return Card(
      elevation: 1,
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Lịch #${booking.id}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(booking.status),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customerPhone.isNotEmpty
                          ? '$customerName - $customerPhone'
                          : customerName,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textPrimary),
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
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${booking.court.name} - ${booking.branch.name}',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textPrimary),
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
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ngày: ${_formatDate(booking.bookingDate)}',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ca: ${_formatSlots(booking.slots)} (${booking.slots.length} ca)',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.borderMuted),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng cộng',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
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
      ),
    );
  }
}
