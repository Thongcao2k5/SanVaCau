class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.data,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  NotificationTarget get target {
    final payload = data ?? const <String, dynamic>{};
    final ticketId = payload['ticketId']?.toString();
    if (ticketId != null && ticketId.isNotEmpty) {
      return NotificationTarget(NotificationTargetKind.support, ticketId);
    }

    final orderId = payload['orderId']?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      return NotificationTarget(NotificationTargetKind.order, orderId);
    }

    final bookingId = payload['bookingId']?.toString();
    if (bookingId != null && bookingId.isNotEmpty) {
      return NotificationTarget(NotificationTargetKind.booking, bookingId);
    }

    final targetType = payload['targetType']?.toString();
    final targetId = payload['targetId']?.toString();
    if (targetId != null && targetId.isNotEmpty) {
      if (targetType == 'ORDER') {
        return NotificationTarget(NotificationTargetKind.order, targetId);
      }
      if (targetType == 'BOOKING') {
        return NotificationTarget(NotificationTargetKind.booking, targetId);
      }
    }

    return const NotificationTarget(NotificationTargetKind.none, '');
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] == true,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      readAt: readAt,
      createdAt: createdAt,
      data: data,
    );
  }
}

enum NotificationTargetKind { none, order, booking, support }

class NotificationTarget {
  const NotificationTarget(this.kind, this.id);

  final NotificationTargetKind kind;
  final String id;
}
