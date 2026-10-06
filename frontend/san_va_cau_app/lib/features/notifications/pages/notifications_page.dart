import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../booking/data/booking_api.dart';
import '../../booking/models/booking.dart';
import '../../booking/pages/booking_detail_page.dart';
import '../../orders/data/order_api.dart';
import '../../orders/pages/order_detail_page.dart';
import '../../support/pages/support_ticket_detail_page.dart';
import '../data/notification_api.dart';
import '../models/notification_item.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationApi _api;
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _error;
  bool _isMarkingAll = false;
  String? _openingNotificationId;

  @override
  void initState() {
    super.initState();
    _api = NotificationApi();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _api.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải thông báo';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll) return;
    final hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    setState(() => _isMarkingAll = true);

    try {
      await _api.markAllAsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra')));
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  Future<void> _markAsRead(int index) async {
    final item = _notifications[index];
    if (item.isRead) return;

    // Optimistic update
    setState(() {
      _notifications[index] = item.copyWith(isRead: true);
    });

    try {
      await _api.markAsRead(item.id);
    } catch (_) {
      // Revert on fail
      if (mounted) {
        setState(() {
          _notifications[index] = item;
        });
      }
    }
  }

  Future<void> _openNotification(int index) async {
    final item = _notifications[index];
    if (_openingNotificationId != null) return;
    setState(() => _openingNotificationId = item.id);

    try {
      await _markAsRead(index);
      if (!mounted) return;

      final target = item.target;
      switch (target.kind) {
        case NotificationTargetKind.order:
          final order = await OrderApi().getMyOrderById(target.id);
          if (!mounted) return;
          await Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => OrderDetailPage(order: order)),
          );
        case NotificationTargetKind.booking:
          final bookings = await BookingApi().getMyBookings();
          Booking? booking;
          for (final candidate in bookings) {
            if (candidate.id == target.id) {
              booking = candidate;
              break;
            }
          }
          if (!mounted) return;
          if (booking == null) {
            throw const ApiException(
              statusCode: 404,
              message: 'Không tìm thấy lịch đặt sân.',
            );
          }
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => BookingDetailPage(booking: booking!),
            ),
          );
        case NotificationTargetKind.support:
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => SupportTicketDetailPage(ticketId: target.id),
            ),
          );
        case NotificationTargetKind.none:
          break;
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở nội dung thông báo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingNotificationId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (!_isLoading && _error == null && hasUnread)
            IconButton(
              icon: _isMarkingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all),
              onPressed: _isMarkingAll ? null : _markAllAsRead,
              tooltip: 'Đánh dấu tất cả đã đọc',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Có lỗi xảy ra',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loadNotifications,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có thông báo',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn chưa nhận được thông báo nào.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loadNotifications,
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return _NotificationCard(
            item: item,
            isOpening: _openingNotificationId == item.id,
            onTap: () => _openNotification(index),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.isOpening,
    required this.onTap,
  });

  final NotificationItem item;
  final bool isOpening;
  final VoidCallback onTap;

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead
              ? AppColors.surface
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item.isRead
                ? AppColors.border
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.isRead
                    ? AppColors.background
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: isOpening
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      item.type.startsWith('ORDER') ||
                              item.type == 'FULFILLMENT_UPDATE'
                          ? Icons.receipt_long
                          : item.type.startsWith('BOOKING')
                          ? Icons.calendar_today
                          : item.type.startsWith('SUPPORT')
                          ? Icons.forum_outlined
                          : Icons.notifications,
                      color: item.isRead
                          ? AppColors.textSecondary
                          : AppColors.primary,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(item.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: item.isRead
                              ? AppColors.textSecondary
                              : AppColors.primary,
                          fontWeight: item.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary, height: 1.4),
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
