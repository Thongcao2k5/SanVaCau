import 'package:flutter_test/flutter_test.dart';
import 'package:san_va_cau_app/features/notifications/models/notification_item.dart';

NotificationItem notificationWith(Map<String, dynamic> data) {
  return NotificationItem.fromJson({
    'id': '1',
    'type': 'TEST',
    'title': 'Test',
    'message': 'Test',
    'isRead': false,
    'createdAt': '2026-10-06T02:00:00.000Z',
    'data': data,
  });
}

void main() {
  test('resolves order, booking and support notification targets', () {
    expect(
      notificationWith({'orderId': '7'}).target.kind,
      NotificationTargetKind.order,
    );
    expect(
      notificationWith({'bookingId': '8'}).target.kind,
      NotificationTargetKind.booking,
    );
    expect(
      notificationWith({'ticketId': '9'}).target.kind,
      NotificationTargetKind.support,
    );
  });

  test('resolves payment target metadata and handles unknown data', () {
    final paymentTarget = notificationWith({
      'paymentId': '4',
      'targetType': 'ORDER',
      'targetId': '11',
    }).target;

    expect(paymentTarget.kind, NotificationTargetKind.order);
    expect(paymentTarget.id, '11');
    expect(
      notificationWith({'reviewId': '2'}).target.kind,
      NotificationTargetKind.none,
    );
  });
}
