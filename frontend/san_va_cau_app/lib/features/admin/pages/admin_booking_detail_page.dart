import 'package:flutter/material.dart';
import 'package:san_va_cau_app/core/network/api_client.dart';
import 'package:san_va_cau_app/core/theme/app_colors.dart';
import 'package:san_va_cau_app/features/booking/data/booking_api.dart';
import 'package:san_va_cau_app/features/booking/models/booking.dart';

class AdminBookingDetailPage extends StatefulWidget {
  const AdminBookingDetailPage({
    super.key,
    required this.booking,
    this.bookingApi,
  });

  final Booking booking;
  final BookingApi? bookingApi;

  @override
  State<AdminBookingDetailPage> createState() => _AdminBookingDetailPageState();
}

class _AdminBookingDetailPageState extends State<AdminBookingDetailPage> {
  late final BookingApi _api = widget.bookingApi ?? BookingApi();
  late final Booking _currentBooking = widget.booking;
  bool _isUpdating = false;

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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateOnly(DateTime? date) {
    if (date == null) return 'Không xác định';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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

  String _getPaymentLabel(String? paymentStatus) {
    switch (paymentStatus?.toUpperCase()) {
      case 'PAID':
        return 'Đã thanh toán';
      case 'UNPAID':
        return 'Chưa thanh toán';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      default:
        return paymentStatus ?? 'Chưa thanh toán';
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_isUpdating) return;

    String dialogTitle = '';
    String dialogContent = '';
    Color confirmColor = AppColors.primary;

    if (newStatus == 'CHECKED_IN') {
      dialogTitle = 'Xác nhận nhận sân';
      dialogContent = 'Khách đã đến và nhận sân?';
      confirmColor = AppColors.warning;
    } else if (newStatus == 'COMPLETED') {
      dialogTitle = 'Xác nhận hoàn tất';
      dialogContent = 'Khách đã sử dụng xong và hoàn tất lịch đặt?';
      confirmColor = AppColors.info;
    } else if (newStatus == 'CANCELLED') {
      dialogTitle = 'Xác nhận hủy lịch';
      dialogContent = 'Bạn có chắc chắn muốn hủy lịch đặt này?';
      confirmColor = AppColors.primary;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
        backgroundColor: AppColors.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Bỏ qua',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedBooking = await _api.updateAdminBookingStatus(
        id: _currentBooking.id,
        status: newStatus,
      );
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật trạng thái thành công'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, updatedBooking);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra, không thể cập nhật lịch'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted && _isUpdating) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFinal =
        _currentBooking.status == 'COMPLETED' ||
        _currentBooking.status == 'CANCELLED';
    final statusColor = _getStatusColor(_currentBooking.status);
    final customerName = _currentBooking.customer?.fullName ?? 'Khách vãng lai';
    final customerPhone = _currentBooking.customer?.phone ?? 'Không có SĐT';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chi tiết lịch đặt'), centerTitle: true),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.borderMuted),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lịch #${_currentBooking.id}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              _getStatusLabel(_currentBooking.status),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.person_outline,
                        'Khách hàng:',
                        customerName,
                      ),
                      if (customerPhone.isNotEmpty &&
                          customerPhone != 'Không có SĐT')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _buildInfoRow(
                            Icons.phone_outlined,
                            'SĐT:',
                            customerPhone,
                          ),
                        ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        'Chi nhánh:',
                        _currentBooking.branch.name,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.sports_tennis_outlined,
                        'Sân:',
                        _currentBooking.court.name,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        'Ngày đặt:',
                        _formatDateOnly(_currentBooking.bookingDate),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Timestamps
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.borderMuted),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời gian',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildTimeRow('Tạo lúc', _currentBooking.createdAt),
                      if (_currentBooking.checkedInAt != null) ...[
                        const SizedBox(height: 8),
                        _buildTimeRow('Nhận sân', _currentBooking.checkedInAt),
                      ],
                      if (_currentBooking.completedAt != null) ...[
                        const SizedBox(height: 8),
                        _buildTimeRow('Hoàn tất', _currentBooking.completedAt),
                      ],
                      if (_currentBooking.cancelledAt != null) ...[
                        const SizedBox(height: 8),
                        _buildTimeRow('Đã hủy', _currentBooking.cancelledAt),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Slots
              Text(
                'Ca đặt sân',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ..._currentBooking.slots.map((slot) {
                return Card(
                  elevation: 0,
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.borderMuted),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.access_time_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${slot.startTime.length >= 5 ? slot.startTime.substring(0, 5) : slot.startTime} - ${slot.endTime.length >= 5 ? slot.endTime.substring(0, 5) : slot.endTime}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(slot.priceAtBooking),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),
              // Payment & Total Amount
              Card(
                elevation: 0,
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Phương thức',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentBooking.paymentMethod ?? 'CASH',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Thanh toán',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getPaymentLabel(_currentBooking.paymentStatus),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _currentBooking.paymentStatus
                                                ?.toUpperCase() ==
                                            'PAID'
                                        ? AppColors.success
                                        : AppColors.textPrimary,
                                  ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: AppColors.border),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng cộng',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatCurrency(_currentBooking.totalAmount),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isUpdating)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isFinal
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_currentBooking.status == 'BOOKED')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUpdating
                              ? null
                              : () => _updateStatus('CHECKED_IN'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: AppColors.onPrimary,
                          ),
                          child: const Text('Nhận sân'),
                        ),
                      ),
                    if (_currentBooking.status == 'CHECKED_IN')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUpdating
                              ? null
                              : () => _updateStatus('COMPLETED'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: AppColors.onPrimary,
                          ),
                          child: const Text('Hoàn tất'),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUpdating
                            ? null
                            : () => _updateStatus('CANCELLED'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                        ),
                        child: const Text('Hủy lịch'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow(String label, DateTime? date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            _formatDate(date),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
